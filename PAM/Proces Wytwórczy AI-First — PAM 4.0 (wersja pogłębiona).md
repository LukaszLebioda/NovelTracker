# Jak budujemy PAM 4.0 — proces AI-first, wersja pogłębiona

> Druga wersja dokumentu „Proces Wytwórczy AI-First — PAM 4.0". Poziom: **średnio-techniczny** —
> dla PM-a, który chce rozumieć mechanikę (lint, merge queue, testy e2e, mocki, tokeny, infrastruktura),
> ale bez żargonu developerskiego. Każdy techniczny termin jest tłumaczony przy pierwszym użyciu
> i zebrany w słowniczku na końcu.
>
> Wersje towarzyszące: „(wersja przystępna)" — całkiem nietechniczna; „Raport Audytowy" — pełny detal.

---

## 1. Fundament: jak w ogóle przechowujemy i zmieniamy system

Zanim o AI — warto zrozumieć „rusztowanie", na którym wszystko stoi.

### Repozytorium Git — księga wieczysta kodu

Cały system (kod, testy, wymagania, dokumentacja, konfiguracja agentów) żyje w **repozytorium Git** — systemie kontroli wersji. Działa to jak księga wieczysta z pełną historią:

- **Commit** = jeden zapisany „wpis do księgi": zestaw zmian z autorem, datą i opisem. Nie da się go po cichu podmienić — historia jest trwała.
- **Gałąź (branch)** = równoległa linia pracy. Nową funkcję budujemy „obok" działającego systemu, na własnej gałęzi, żeby niczego nie zepsuć w trakcie.
- **Gałąź `main`** = wersja główna, „prawda o systemie". Wszystko, co tu trafi, uważamy za działające.
- **Pull Request (PR)** = formalny wniosek „chcę wlać moją gałąź do `main`". To nie jest kliknięcie „zapisz" — PR przechodzi przeglądy i automatyczne kontrole.

W naszym procesie obowiązuje zasada **jeden etap pracy agenta = jeden commit**. Dzięki temu historię każdej funkcji da się odtworzyć krok po kroku: wymagania → krytyka → projekt → testy → kod → recenzja → dokumentacja.

### Monorepo — wszystko w jednym miejscu

Nie mamy kilkunastu osobnych repozytoriów, tylko **jedno wspólne (monorepo)**, zarządzane narzędziem Turborepo + Yarn. W środku:

| Element | Co to jest — po ludzku |
|---|---|
| `apps/pam-api` | **Backend** — „mózg" systemu: logika biznesowa, baza danych, integracje z płatnościami i Keycloak (system logowania). Napisany w NestJS (framework dla serwerów w języku TypeScript). |
| `apps/pam-ui` | **Frontend** — to, co widzi użytkownik: panel administracyjny w React (biblioteka do interfejsów), budowany narzędziem Vite. |
| `apps/pam-worker` | **Pracownik tła** — program bez interfejsu, który wykonuje zadania cykliczne (np. „co 5 minut sprawdź przeterminowane wpłaty"). Celowo wydzielony z API, żeby ciężkie zadania nie spowalniały obsługi użytkowników. |
| `apps/pam-event-bridge` | **Mostek zdarzeń** — przekazuje informacje o tym, co się stało w systemie (np. „gracz wpłacił 100 zł"), do zewnętrznego archiwum analitycznego przez systemy kolejkowe RabbitMQ i Kafka. |
| `apps/pam-notifier` | **Rozsyłacz powiadomień** — odbiera z kolejki komunikaty i zajmuje się ich dostarczeniem. |
| `apps/migrator` | **Narzędzie do zmian w bazie danych** — uruchamia migracje (patrz niżej) w trybie awaryjnie-bezpiecznym. |
| `packages/contracts` | **Wspólny słownik** — definicje kształtu danych wymienianych między frontendem a backendem (schematy Zod). Jedno źródło prawdy: jeśli backend zmieni format odpowiedzi, frontend dostanie błąd kompilacji, a nie cichą awarię na produkcji. |
| `packages/db` | **Schemat bazy danych** — definicje ~70 tabel + ~65 migracji (kolejnych wersji zmian struktury bazy) dla PostgreSQL. |
| `packages/backend-shared` | **Części wspólne** backendu (połączenia z bazą, publikacja zdarzeń, sprawdzanie „żywości" usług). |

Dlaczego monorepo przy pracy z AI? Bo agent widzi **cały kontekst w jednym miejscu** — zmianę w backendzie i odpowiadającą jej zmianę w frontendzie robi się i weryfikuje razem, a wspólny słownik (`contracts`) pilnuje spójności automatycznie.

### Infrastrura — gdzie to wszystko działa

- **GitHub Enterprise Cloud (organizacja NTP/NOVOMATIC)** — korporacyjna, wydzielona instancja GitHuba: hosting kodu, PR-y, kolejka scalania, automatyzacje (GitHub Actions). Logowanie firmowym SSO.
- **Kubernetes + Helm** (`deploy/k8s`) — docelowe środowisko produkcyjne: system „orkiestracji kontenerów", który uruchamia nasze aplikacje w izolowanych paczkach (kontenerach), pilnuje ich restartowania i skalowania.
- **Docker Compose** — lokalne środowisko developerskie: jednym poleceniem stawia bazę danych, kolejki i wszystkie aplikacje na komputerze inżyniera.
- **Netlify** — zewnętrzna platforma do **podglądów UI** (rozdział 9): każdy PR z interfejsem dostaje własny, klikalny adres www.
- **Nexus** — wewnętrzny rejestr paczek i obrazów: nic nie pobieramy „z internetu" bezpośrednio, tylko z kontrolowanego, firmowego źródła.
- **Kilo Gateway** — pojedyncza bramka (proxy), przez którą przechodzą **wszystkie** zapytania agentów do modeli AI. Daje kontrolę dostępu, limity i audytowalność.

---

## 2. Zanim kod trafi do `main`: lint, typy, merge queue

To najczęściej padające słowa na audycie — wyjaśniamy dokładnie, co robią.

### Lint / linter — automatyczny korektor stylu i błędów

**Linter** to program, który czyta kod i wytyka problemy **bez uruchamiania go**: niespójne nazewnictwo, nieużywane zmienne, podejrzane konstrukcje, złamanie ustalonych reguł zespołu. Analogia: automatyczny korektor w Wordzie, tylko dla kodu i z regułami, które sami definiujemy.

U nas linter (ESLint) robi też rzeczy „bezpieczeństwowe":
- **blokuje importy między aplikacjami** — np. backend nie może „pożyczyć" kodu frontendu; granice są wymuszone technicznie, nie dobrymi chęciami,
- **linter migracji SQL** sprawdza zmiany w bazie danych — np. zakazuje operacji, które zablokowałyby tabelę księgi finansowej (portfel gracza) podczas pracy systemu, albo wymusza tworzenie indeksów „w tle" (`CONCURRENTLY` — tryb, który nie zatrzymuje działania bazy).

Jeśli linter mówi „nie", zmiana nie przejdzie dalej. To **twarda bramka**, nie sugestia.

### Check typów (typecheck) — kompilator jako strażnik

Piszemy w **TypeScript** — odmianie JavaScriptu, w której każda dana ma zadeklarowany „typ" (liczba, tekst, obiekt gracza...). **Kompilator** sprawdza spójność tych typów w całym projekcie, zanim cokolwiek uruchomimy. Efekt praktyczny:

- jeśli backend zmieni format danych, a frontend się nie dostosuje — **projekt się nie skompiluje**, błąd wyjdzie od razu, a nie u gracza;
- uprawnienia (kto co może w systemie) też są pilnowane typami: użycie nowego uprawnienia bez zarejestrowania go w słowniku = błąd kompilacji.

### Testy — jakie rodzaje i po co

| Rodzaj testu | Co sprawdza | U nas |
|---|---|---|
| **Jednostkowe (unit)** | Pojedynczy, mały kawałek logiki w izolacji („czy funkcja licząca bonus działa dla zera, dla wartości ujemnych...") | uruchamiane przy każdej zmianie |
| **Integracyjne** | Współpracę kilku elementów, np. serwis + prawdziwa baza danych — ale **w pamięci**, bez serwera (używamy PGlite: miniaturowy PostgreSQL działający w procesie testu, znikający po zakończeniu) | j.w. |
| **E2E (end-to-end, „od końca do końca")** | Cały przepływ tak, jak przeżywa go użytkownik: wystartuj aplikację, wyślij żądanie HTTP przez sieć, sprawdź odpowiedź i stan bazy. Najbliższe „prawdziwemu życiu" | **~140 takich specyfikacji** dla samego backendu; testowane narzędziem supertest |
| **Komponentowe / użytkownika (frontend)** | Czy ekran renderuje się poprawnie i czy „kliknij wpłatę → pokaż potwierdzenie" działa — w symulowanej przeglądarce (jsdom), z Testing Library | ~140 plików testowych UI |
| **Kontraktowe** | Czy dane testowe (mocki) wciąż pasują do słownika `contracts` | w pakiecie kontraktów |

**Mock** (atrapa) — podstawa testowania: zamiast łączyć się z prawdziwym bankiem czy bramką płatniczą, test rozmawia z ** atrapą udającą** taką usługę i zwracającą z góry ustalone odpowiedzi. Dzięki temu testy są szybkie, powtarzalne i nie ruszają prawdziwych systemów. U nas mocki nie są „byle jakie" — muszą pasować do schematów w `packages/contracts`, więc atrapa nie może się rozjechać z rzeczywistością.

**Skala:** ~145 tys. linii testów na ~85 tys. linii kodu produkcyjnego (**1,7 linii testu na linię kodu**), 419 plików testowych. To nietypowo gęsta siatka — i celowo: przy kodzie pisanym przez AI testy są głównym mechanizmem zaufania.

### Pokrycie kodu (coverage)

Metryka mówiąca, **jaki procent kodu został wykonany podczas testów**. Nie jest celem samym w sobie (100% coverage bez sensownych sprawdzeń nic nie znaczy — dlatego mamy też audyt asercji, rozdział 4), ale progi pokrycia są w roadmapie jako twarda bramka.

### CI i Merge Queue — bramka, której nie da się obejść

**CI (Continuous Integration)** = automatyczne kontrole uruchamiane na serwerze (GitHub Actions) przy każdej zmianie. U nas 8 takich „workflowów"; najważniejszy (`quality.yml`) wykonuje: zamrożoną instalację zależności → lint (w tym linter SQL) → pełny check typów → testy jednostkowe i integracyjne. Mediana: **~4 minuty**, awaryjność **<2%**.

**Merge Queue (kolejka scalania)** — kluczowy mechanizm, warto go umieć opisać:

1. Człowiek klika „scal do `main`". Zmiana **nie trafia tam od razu** — ląduje w kolejce.
2. Kolejka bierze tę zmianę, **łączy ją próbnie z aktualnym `main` (i ze zmianami czekającymi przed nią w kolejce)** i na tej „przyszłej wersji main" uruchamia pełne testy.
3. Dopiero gdy wszystko jest zielone, scalenie faktycznie następuje.

Dlaczego to ważne: dwie zmiany mogą być osobno poprawne, ale **razem** się gryźć („u mnie działało"). Kolejka testuje dokładnie tę kombinację, która trafi do `main`. Efekt: `main` jest zawsze w stanie zbudowanym i przetestowanym.

**Zasada nadrzędna: scalenie zatwierdza wyłącznie człowiek.** Automaty (w tym nocny agent) nigdy nie piszą do `main`.

### Lokalna pętla `/pre-push-verify`

Zanim inżynier w ogóle wyśle zmianę na serwer, uruchamia jedną komendę agentową, która przechodzi **cały łańcuch** lokalnie: instalacja → lint → lint specyfikacji → check typów → testy → raport pokrycia → build → e2e. Jeśli coś padnie, agent naprawia i ponawia, aż będzie zielone. Dzięki temu na serwer rzadko docierają zmiany „zepsute od progu", a kolejka scalania nie marnuje cykli.

---

## 3. Flow SDD — 7 etapów, 9 agentów, twarde uprawnienia

(Skrót z wersji przystępnej: najpierw specyfikacja i jej krytyka, akceptacja człowieka, potem projekt → testy → kod → recenzja → dokumentacja. Tu schodzimy w mechanikę.)

### Agenci i separacja ról

Każdy etap wykonuje **osobny agent** — konfiguracja zawierająca: instrukcję systemową (rolę), przypisany model AI, limit kroków i **listę uprawnień do plików**. Kluczowe restrykcje:

| Agent | Co wolno | Czego NIE wolno (twarda blokada techniczna) |
|---|---|---|
| Orkiestrator | prowadzić dziennik stanu, delegować etapy | dotykać specyfikacji `.feature` i kodu |
| Analityk | **jako jedyny** zapisywać pliki `.feature` | zmieniać wymagania bez pytania człowieka |
| Krytyk | pisać raport recenzji | edytować specyfikację (żeby „poprawić po cichu") |
| Autor testów | pliki testów i mocków | kod produkcyjny (żeby nie napisał kodu „pod siebie") |
| Implementer | kod w `apps/**`, `packages/**` | edycja `.feature` (żeby nie „dopasował" specyfikacji do kodu) |
| Recenzent | raporty; shell tylko do odczytu | jakiekolwiek zmiany w kodzie |
| Dokumentalista | `docs/**` | kod |

Zasada: **kto pisze, nie odbiera; kto odbiera, nie pisze.** Krytyk, implementer i recenzent to modele **trzech różnych dostawców** — recenzent patrzy na kod „obcego" modelu, bez rozpoznawania własnego stylu.

### Stan procesu w repozytorium, nie w czacie

Rozmowa z AI jest ulotna i zawodna, więc **stan flow nie żyje w czacie**. Każdy etap dopisuje jedną linię do dziennika (append-only): `[STATUS] płatności/timeout-wpłaty implement done` albo `blocked: spec-change-required`. Orkiestrator ocenia postęp **wyłącznie** na podstawie tego pliku. Efekt: proces można przerwać, wznowić, przeaudytować po miesiącu — wszystko jest w Git.

### Pętla rewizji i bezpiecznik (circuit breaker)

Każdy etap techniczny może orzec: „problem leży w specyfikacji" (`spec-change-required`). Wtedy praca **cofa się do analityka** (tryb `--revise`), przechodzi ponownie krytykę i wraca na właściwe miejsce. Limit: **3 próby** — po trzeciej nieudanej flow staje i człowiek dostaje raport blokady. Agenci nie mielą w nieskończoność i nie „naprawiają" testów na siłę.

W liczbach (kwartał): ~940 wpisów etapowych na ~100 funkcji, ~70 rewizji specyfikacji, ~65 twardych blokad (w tym ~30 cofnięć do analityka z etapów technicznych). Recenzent-AI zablokował wdrożenie 28 razy — kontrola działa naprawdę, nie dekoracyjnie.

### Bramki etapowe — co dokładnie musi być spełnione

| Etap | Warunek przejścia (mierzalny) |
|---|---|
| gather | `spec:lint` = 0 błędów; każda reguła z briefu ma scenariusz |
| critique | każdy tag `@req` w scenariuszach rozwiązuje się do istniejącego wymagania; operacje asynchroniczne mają zdefiniowany kontrakt |
| design | manifest kontraktów istnieje; pełny check typów przechodzi |
| test (red) | testy się kompilują i **failują wyłącznie na asercjach** — nie wolno im failować z powodu „nie ma takiego pliku/metody" (to znaczyłoby, że test nic nie sprawdza) |
| implement (green) | e2e + lint + check typów + build przechodzą we wszystkich dotkniętych aplikacjach; zakaz „wiecznie zielonych" sprawdzeń i pustych implementacji |
| review | audyt anty-oszustwowy (rozdział 4) |
| document | kod zgodny z zatwierdzonym Gherkinem; inaczej dokumentacja nie jest publikowana, powstaje raport rozbieżności |

**`spec:lint`** — nasz własny linter specyfikacji (osobny od lintera kodu). Sprawdza m.in.: składnię Gherkina, czy każdy scenariusz ma tag wymagania, który faktycznie istnieje w `requirements.md`, czy tabele przykładów nie są puste, czy nazwy scenariuszy się nie duplikują, oraz — sprytnie — **czy symbole techniczne deklarowane w specyfikacji faktycznie istnieją w kodzie** (wołając kompilator TypeScript). To most pilnujący, żeby dokumentacja nie rozjeżdżała się z implementacją.

---

## 4. Audyt „anty-ściema" (anti-cheat) — bo AI bywa sprytnie leniwe

Znany problem z modelami AI: gdy test nie chce przejść, najłatwiejszą „naprawą" jest **osłabić test** albo wstawić atrapę udającą działanie. Nasz etap review to wykrywa:

- **diff testów**: automat porównuje zmiany w plikach testowych — czy nie usunięto sprawdzeń (`expect(...)`, `toBe(...)`)? Usunięta asercja = czerwona flaga.
- **audyt zamrożenia Gherkina**: historia Git jest pytana, kto dotykał plików `.feature`. Zmiana wykonana przez kogokolwiek innego niż agent-analityk = PR odrzucony.
- **skan zaślepek**: nowy kod jest przeszukiwany pod kątem `TODO`, `FIXME`, funkcji-pustaków i sztucznych mocków w kodzie produkcyjnym.
- **`spec:lint --strict`**: każdy znacznik `@todo` („do uzupełnienia") w specyfikacji = błąd krytyczny.

To konkretna realizacja zasady **„twarde reguły wygrywają z instrukcjami"**: zamiast prosić model „nie oszukuj", budujemy automat, który oszustwo wykrywa.

---

## 5. Tokeny, kontekst i „inżynieria kontekstu" — dlaczego AI nie czyta całego repo

### Co to jest token i kontekst

Model AI czyta i pisze **tokenami** — jednostkami tekstu wielkości mniej więcej pół słowa. **Okno kontekstu** to „pamięć operacyjna" modelu: wszystko, co widzi podczas pracy (instrukcje + przeczytane pliki + historia rozmowy). Jest skończone.

Kluczowe zjawisko: **context rot** („gnicie uwagi") — im więcej niepotrzebnych treści w kontekście, tym gorzej model rozumie zadanie. Model zasypany całym repozytorium zaczyna gubić szczegóły i halucynować. To nie metafora, to obserwowalny spadek jakości.

### Nasze odpowiedzi

1. **Twardy budżet: ≤170 tys. tokenów na sesję.** Agenci nie ładują całych plików — czytają punktowo (fragment o zadanym zakresie linii, wyszukiwanie po wzorcu `grep`, po nazwie pliku `glob`, albo **wyszukiwanie semantyczne** — „znajdź kod, który *znaczy* to i to", działające na lokalnym indeksie podobieństwa).
2. **Warstwowe instrukcje.** Zawsze załadowane są tylko krótkie reguły bazowe (`AGENTS.md` + 3 pliki zasad: core/backend/frontend). Reszta wiedzy to **15 skilli** — instrukcji „na żądanie" doczytywanych tylko wtedy, gdy zadanie ich dotyczy (np. skill „jak bezpiecznie zrobić migrację bazy" ładuje się tylko przy migracji). Jak biblioteka, w której na biurku leży tylko potrzebna książka.
3. **Atomowe zadania.** Jedno zadanie = jeden wycinek: schemat bazy + migracja ALBO jeden zasób API ALBO jeden ekran. „Mega-PR-y" są zakazane — bo duży zakres = duży kontekst = context rot.
4. **Architektura pod małe porcje.** Kod jest celowo rozdrobniony: mediana pliku produkcyjnego to **~40 linii**, tylko ~1% plików przekracza 500 linii. Domeny komunikują się przez wąskie, dobrze nazwane **porty** (~40 takich interfejsów, np. „bramka wypłat", „blokada logowania przy wykluczeniu") zamiast sięgać sobie nawzajem do danych. Zakaz zapytań SQL „na skróty" między domenami. Dzięki temu agent może zrozumieć i bezpiecznie zmienić jeden moduł, nie czytając połowy systemu.

Ta sama architektura, która jest dobra dla AI, jest po prostu **dobrą architekturą** — małe moduły, jawne granice, brak skrótów.

---

## 6. Modele AI i Kilo Gateway — routing, pinning, koszty

### Routing: trzy klasy modeli

Nie wszystko wymaga najmocniejszego modelu (jak nie każde pismo wymaga prezesa):

| Klasa | Zadania | Przykładowe modele |
|---|---|---|
| **Szybka/tania** | orkiestracja, dokumentacja, raporty nocne, generowanie testów | DeepSeek v4 Flash, GLM 5.3 Flash |
| **Analityczna** | wymagania, Gherkin, krytyka specyfikacji | GLM 5.3, Gemini 3.8 Flash |
| **Najmocniejsza** | architektura, kod produkcyjny, niezależne review, rozwiązywanie konfliktów | DeepSeek v4 Pro, Grok 4.6, Qwen 3.8 Max |

**Kilo Gateway** to centralne proxy: jedno miejsce, przez które idą wszystkie zapytania do wszystkich dostawców. Daje: autoryzację, limity, audyt zużycia tokenów i jeden punkt kontroli bezpieczeństwa (nic nie „dzwoni do OpenAI bokiem").

### Pinning wersji

Modele przypinamy do **konkretnej wersji z datą wydania** (np. `deepseek-v4-pro-0813`). Dostawcy potrafią po cichu zmieniać zachowanie modelu „o tej samej nazwie" — u nas zmiana modelu jest jawnym commitem z uzasadnieniem. W ciągu kwartała było ~6 takich rotacji, zawsze w reakcji na mierzoną jakość lub koszt (np. wycofanie Gemini Flash Lite — za słaba jakość; porównanie GPT-5.6 Luna vs Grok 4.6 na roli implementera — wygrał Grok).

### Hybryda „skrypt + LLM"

Zasada przekrojowa: **mechanikę robi deterministyczny kod, model robi tylko wąski krok semantyczny**. Git, API, parsowanie — skrypty (TypeScript/Python) z własnymi testami. LLM dostaje minimalny, przygotowany payload (np. sam skonfliktowany fragment jako JSON) i odpowiada w sztywnym formacie. To tańsze o rzędy wielkości i bezpieczniejsze niż „pełna autonomia modelu".

---

## 7. Środowisko pracy: Kilo Code, Agent Manager, worktrees, MCP

- **Kilo Code** — narzędzie, w którym działają agenci (wtyczka VS Code + CLI). Cała konfiguracja (9 agentów, 10 komend, 15 skilli, reguły) leży **w repozytorium** w katalogu `.kilo/` — jest wersjonowana i recenzowana jak kod. Zmiana zachowania agenta = PR.
- **Git Worktree + Agent Manager** — worktree to mechanizm Gita pozwalający mieć **kilka katalogów roboczych tej samej repozytorium**, każdy na innej gałęzi. Agent Manager zarządza nimi z poziomu edytora. Efekt: jeden inżynier prowadzi równolegle np. dwie funkcje biznesowe i poprawkę DevOps — każdy strumień w osobnym „pokoju" z własną gałęzią i zależnościami, w szczycie ~10 aktywnych. Skrypt inicjalizujący kopiuje konfigurację, instaluje zależności i weryfikuje środowisko (z bezpiecznikiem: nie da się go odpalić w głównym katalogu).
- **MCP (Model Context Protocol)** — standard bezpiecznego podłączania agentów do narzędzi firmowych. U nas: serwer MCP dla **Jiry i Confluence**, działający w jednorazowym kontenerze z obrazem przypiętym do sumy kontrolnej sha256. Agenci czytają zgłoszenia, ale przez kontrolowany, wąski interfejs.
- **Wyszukiwanie semantyczne** — lokalny indeks „znaczenia" kodu (model embeddingów `mistral-embed`), dzięki któremu agent znajduje kod po intencji („gdzie obsługujemy wykluczenia gracza?"), a nie tylko po słowach.

---

## 8. Nocny agent — jak dokładnie działa autonomiczny rebase

### Problem (zmierzony, nie wrażeniowy)

90 dni historii: ~100 PR-ów, 224 recenzje. Aktywność nocna/weekendowa: ~0%. **~70% PR-ów wymagało ręcznego rebase'u, średnio 3,4 raza na PR.**

**Rebase** — wyjaśnienie: gdy twoja gałąź „odkleiła się" od `main` (bo w międzyczasie weszły inne zmiany), trzeba ją **przesadzić na najnowszy `main`** i rozwiązać konflikty (sytuacje, gdy dwie zmiany dotknęły tych samych linii). To praca mechaniczna, ale wymagająca skupienia — idealny kandydat do automatyzacji.

### Przebieg (dwie nocne godziny)

**02:00 UTC — okno raportowe** (tani model, temperatura 0 = maksymalna deterministyczność):
- raport checków z poprzedniego dnia z rozdziałem: **twarde błędy vs testy niestabilne (flaky)** — flaky to test, który raz przechodzi, raz nie, bez zmiany kodu; zatruwa sygnał jakości, więc jest wyłapywany osobno,
- gałęzie nieaktywne >14 dni,
- stan rebase i gotowość PR-ów.

**03:00 UTC — okno aktywnego rebase** (mocniejszy model):
1. pobranie otwartych PR-ów (bez draftów, kolejki scalania i bota od zależności),
2. **próbny** rebase w osobnym worktree — nic nie jest ruszane „na żywo",
3. klasyfikacja konfliktu: **prosty** (≤3 pliki, ≤30 skonfliktowanych linii) → model dostaje *wyłącznie* skonfliktowane fragmenty jako JSON i decyduje `resolve` albo `abort`; **złożony lub na pliku wykluczonym** → `abort` z uzasadnieniem, zostaje dla człowieka,
4. wypchnięcie gałęzi przez GitHub App z flagą `--force-with-lease` (bezpieczne nadpisanie: nie zadziała, jeśli ktoś w międzyczasie coś dopchnął) — limit 10 PR-ów na noc,
5. czekanie na check CI (do 25 min): **zielony** → gałąź zostaje + komentarz w PR; **czerwony** → **automatyczny rollback** do poprzedniego stanu (SHA) + raport,
6. maskowanie sekretów w logach.

### Zabezpieczenia

- **Model nie steruje Gitem** — całą mechanikę robi skrypt Pythona z własnymi testami jednostkowymi; LLM to tylko „procesor tekstu" odpowiadający JSON-em.
- **Twarda lista wykluczeń**: `.github/**`, migracje SQL, lockfile'y, `.env*`, klucze i certyfikaty — automat nigdy ich nie dotknie.
- **Walidacja odpowiedzi modelu**: odpowiedź zawierająca znaczniki konfliktu albo niekompletna jest odrzucana.
- **Każda zmiana przechodzi pełne CI; porażka = rollback.** Automat nigdy nie dotyka `main`.

---

## 9. Pętla z interesariuszami — narzędzia i mechanika

```
Repozytorium (źródło prawdy)
   │ publikacja (~45 notatek)              ▲ import zwrotny (codziennie 07:00 UTC → PR needs-po-review)
   ▼                                       │
 HackMD Book ◄── komentarze, sugestie, decyzje Q-* ──► Biznes / PO

 PR z pam-ui ──► Netlify Preview (mocki MSW) ──► Feedbucket ──► GitHub Issues ──► triaż nadzorców
                                                                                    ├─ usterka UI → poprawka
                                                                                    └─ zmiana reguły → EARS → rewizja Gherkina
```

- **HackMD** — edytor online do współdzielenia dokumentów (wymagania, makiety). Publikujemy ~45 notatek; macierz śledzenia, pliki `.feature` i archiwum legacy są **technicznie filtrowane** z publikacji. Import zwrotny: workflow codziennie pobiera edycje biznesu i otwiera PR z etykietami `stakeholder-feedback` + `needs-po-review` — czyli **uwagi biznesu też przechodzą przez przegląd człowieka**.
- **Netlify Preview + MSW** — każdy PR zawierający UI dostaje własny podgląd www. Działa **bez backendu i bazy**: żądania sieciowe przechwytuje **MSW (Mock Service Worker)** — warstwa atrap wbudowana w przeglądarkę, zwracająca dane zgodne z kontraktami z `packages/contracts`. Dzięki temu biznes klika realny interfejs w kilka minut po zmianie, a podgląd nie może „zepsuć" żadnych prawdziwych danych.
- **Feedbucket** — widget na podglądzie: klikasz element ekranu, przypinasz uwagę. Webhook (automatyczne powiadomienie HTTP, z kryptograficzną weryfikacją podpisu) zamienia ją w issue w GitHub Enterprise. Triaż: usterka wizualna → kod; zmiana reguły → najpierw wymagania EARS, potem pełny cykl SDD. **Żadna zmiana reguły nie wchodzi do systemu „z pinezki" z pominięciem procesu.**

---

## 10. Bezpieczeństwo — konkrety, nie deklaracje

1. **Kod**: dedykowana instancja GitHub Enterprise NOVOMATIC, SSO; paczki i obrazy wyłącznie z wewnętrznego Nexusa.
2. **Jeden kanał do modeli**: cały ruch przez Kilo Gateway; klucze w GitHub Actions Secrets; logi automatów maskowane (funkcja `redact()`).
3. **No-training**: umowy z dostawcami gwarantują, że prompty/kod **nie są używane do trenowania modeli**. Warunki (retencja, region) weryfikowane per dostawca; formalny rejestr dostawców — w roadmapzie polityki AI.
4. **Zero danych produkcyjnych i osobowych w promptach**: atomowe zadania ograniczają payload do pojedynczych modułów; makiety, podglądy i testy działają wyłącznie na danych fikcyjnych (PGlite + mocki `MOCK_*`).
5. **Separacja warstw**: dokumenty wewnętrzne (traceability, `.feature`, legacy) filtrowane przed publikacją do biznesu; przewodnik interesariusza zakazuje wklejania haseł i danych osobowych.
6. **Sekrety**: `.gitignore` blokuje `.env*`, katalogi sekretów, certyfikaty; reguła bazowa agentów „never commit or log secrets"; kontenery narzędziowe efemeryczne (`--rm`).
7. **Łańcuch dostaw**: `yarn install --immutable` wszędzie (zamrożone, weryfikowalne drzewo zależności — nie da się „po cichu" pobrać innej wersji biblioteki); akcje GitHub przypięte do SHA, obraz MCP do sha256; przypinanie obrazów bazowych do digestów w toku. W roadmapie: `npm audit`, gitleaks (skaner sekretów), Dependabot/Renovate, SAST (statyczna analiza bezpieczeństwa).
8. **Baza danych**: migrator działa **fail-closed** z `lock_timeout=5s` — jeśli zmiana musiałaby czekać na blokadę tabeli dłużej niż 5 sekund, wdrożenie **przerywa się samo**, zamiast paraliżować bazę. Narzędzie ponawiania zgubionych zdarzeń (DLQ replay) pozwala tylko obejrzeć i ponowić (bez kasowania), wymaga podania operatora i powodu, a każde użycie ląduje w tabeli audytowej.

---

## 11. Zarządzanie procesem — jak to jest „trzymane w ryzach"

- **Wymagania**: źródło prawdy to pliki w repo (nie Confluence, nie maile). Zmiana wymagania = PR z `needs-po-review` = jawna decyzja z autorem i datą.
- **Decyzje**: ~320 pytań `Q-*`, wszystkie rozstrzygnięte i zapisane. Wniosek zarządczy: **wąskim gardłem jest przepustowość decyzji biznesowych, nie kod** — dlatego roadmapa wprowadza „właściciela i termin dla każdego Q-*".
- **Priorytety**: MoSCoW przy każdym wymaganiu (~70% Must / 25% Should / 5% Could).
- **Odpowiedzialność**: za każdy commit odpowiada człowiek; brak atrybucji AI w historii (`Co-Authored-By` zakazane) — odpowiedzialność jest niepodzielna.
- **Audytowalność**: dziennik `[STATUS]` (append-only), jeden commit na etap, artefakty per funkcja (review, kontrakty, plan implementacji, code review, coverage), 12 decyzji architektonicznych (ADR) z uzasadnieniem.
- **Skala nadzoru**: na ~100 PR-ów przypadły **200+ recenzje** (ludzkie i agentowe). Nadzorcy nie czytają rutynowego kodu linia po linii — przeglądają **artefakty w punktach kontrolnych**, zmiany bazy danych i PR-y przed scaleniem.
- **Roadmapa zarządcza**: metryki przepływu (czas i koszt tokenów per etap/funkcja, liczba prób, zadziałania bezpiecznika, defekty po scaleniu), CODEOWNERS + obowiązkowy przegląd ludzki dla domen wysokiego ryzyka (portfel, płatności, odpowiedzialna gra, auth, RBAC), formalna polityka AI uzgodniona ze standardami Grupy.

---

## 12. Liczby — ściągawka

| | |
|---|---|
| Okres / zespół | ~3 miesiące / koordynator + 3 nadzorców |
| Kod produkcyjny | ~85 tys. linii, 1 130 plików (mediana ~40 linii/plik) |
| Testy | ~145 tys. linii (1,7× kodu), 419 plików, ~140 specyfikacji e2e |
| Wymagania / pytania | ~250 EARS w 13 domenach / ~320 Q-*, wszystkie rozstrzygnięte |
| Scenariusze Gherkin | ~100 plików, ~4 000 scenariuszy, 5 128 tagów `@req` |
| Dokumentacja | ~290 dokumentów (Dev/DevOps/Operator), ~200 diagramów |
| Baza danych | ~65 migracji, ~70 tabel |
| Konfiguracja agentowa | 9 agentów, 10 komend, 15 skilli, 3 reguły stałe |
| CI | 8 workflowów; główny check ~4 min; awaryjność <2% |
| Ślad procesu | ~940 wpisów `[STATUS]`, ~65 blokad, ~70 rewizji specyfikacji |

---

## 13. Słowniczek rozszerzony

| Pojęcie | Wyjaśnienie |
|---|---|
| **Git / repozytorium / commit / branch / PR** | System kontroli wersji: trwała historia zmian (commit), równoległe linie pracy (branch), formalny wniosek o scalenie (pull request) |
| **`main`** | Gałąź główna — kanoniczna, zawsze działająca wersja systemu |
| **Rebase** | „Przesadzenie" gałęzi na najnowszą wersję główną i rozwiązanie konfliktów |
| **Merge Queue** | Kolejka scalająca zmiany do `main` dopiero po przetestowaniu ich *razem* z aktualnym `main` |
| **CI (Continuous Integration)** | Automatyczne kontrole (lint, typy, testy, build) uruchamiane na serwerze przy każdej zmianie |
| **Lint / linter** | Statyczna analiza kodu: wytyka błędy i złamania reguł bez uruchamiania programu |
| **Check typów / TypeScript / kompilator** | Weryfikacja spójności „kształtów danych" w całym projekcie przed uruchomieniem |
| **Test jednostkowy / integracyjny / e2e** | Coraz szersze kręgi sprawdzania: funkcja → współpracujące elementy z bazą → cały przepływ przez sieć, jak u użytkownika |
| **PGlite** | Miniaturowy PostgreSQL działający w pamięci procesu testowego — prawdziwa baza bez serwera |
| **Mock / MSW / fixture** | Atrapa zewnętrznej usługi/danych; MSW przechwytuje żądania w przeglądarce; fixture'y to gotowe zestawy danych testowych zgodne z kontraktami |
| **Asercja** | Konkretne sprawdzenie w teście: „oczekuję, że wynik = X". Test bez asercji nic nie weryfikuje |
| **Coverage (pokrycie)** | Procent kodu wykonanego podczas testów |
| **Flaky test** | Test niestabilny: raz zielony, raz czerwony bez zmiany kodu — zatruwa sygnał jakości |
| **Token / okno kontekstu / context rot** | Jednostka tekstu modelu AI / jego „pamięć operacyjna" / degradacja jakości przy przeładowaniu kontekstu |
| **Embedding / wyszukiwanie semantyczne** | Liczbowa reprezentacja „znaczenia" tekstu; pozwala szukać kodu po intencji, nie po słowach |
| **Pinning (przypięcie wersji)** | Zamrożenie konkretnej wersji modelu/obrazu/akcji — zmiana tylko jawną decyzją |
| **Kilo Gateway** | Centralne proxy do modeli AI: routing, autoryzacja, limity, audyt tokenów |
| **MCP** | Standard bezpiecznego podłączania agentów do narzędzi (Jira, Confluence) |
| **Worktree** | Kilka izolowanych katalogów roboczych jednego repozytorium — praca równoległa bez konfliktów |
| **Webhook** | Automatyczne powiadomienie HTTP między systemami („stało się X — oto dane") |
| **Migracja / DDL** | Wersjonowana zmiana struktury bazy danych (tabele, kolumny, indeksy) |
| **Fail-closed** | Zachowanie „w razie wątpliwości przerwij", zamiast „przepchnij dalej" |
| **SAST / gitleaks / npm audit** | Statyczne skanowanie bezpieczeństwa / wykrywanie sekretów w repo / audyt podatności zależności |
| **ADR** | Krótki, wersjonowany zapis ważnej decyzji architektonicznej z uzasadnieniem |
| **RBAC** | Model uprawnień „kto jaką rolę ma, ta rola pozwala na X" — u nas pilnowany typami |
| **SHA / sha256 / digest** | Kryptograficzna suma kontrolna — jednoznaczny „odcisk palca" wersji pliku/obrazu |
| **Rollback** | Automatyczne przywrócenie poprzedniego stanu po nieudanej zmianie |
