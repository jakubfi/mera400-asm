# MEMTEST

**Test pamięci MARCH C- dla minikomputera MERA-400**

## Tryby pracy

W zależności od ustawienia kluczy binarnych podczas startu systemu test pracuje w trybie bez terminala bądź konwersacyjnym.

Znaczenie kluczy:

* klucze `3-7` - ilość modułów do testowania (wartości >16 oznaczają 16 - "wszystkie moduły")
* klucze `8-10`: adres jednostki sterującej terminala
* klucze `11-14`: adres kanału znakowego
* klucz `15`: `0` - test modułów standardowych, `1` - test modułów MEGA

Możliwe są trzy tryby pracy:

1. **Bez terminala, w pełni automatyczna**

   Wybierany, jeśli wszystkie klucze ustawione zostaną na `0`.
   Test znajduje dostępne kwanty pamięci (zarówno starndardowej
   jak i MEGA) i uruchamia na nich w pętli test MARCH C-.

3. **Bez terminala, ze wskazaniem modułów do testowania**

   Jeśli na kluczach `8-14` ustawione jest `0`, pozostałe klucze pozwalają zawęzić
   obszar testu automatycznego, np:
     * klucz `15`=`0`, klucze `3-7`=`00011` (3 wybrane moduły): testuj moduły podstawowe 0-2
     * klucz `15`=`1`, klucze `3-7`=`00100` (4 wybrane moduły): testuj moduły MEGA 12-15
       (moduły MEGA instalowane są od najwyższych "w dół")

4. **Konwersacyjna**

   Jeśli na kluczach `8-14` podany jest adres terminala, to zostanie on użyty
   do dialogu z użytkownikiem: pokazania konfiguracji pamięci,
   wyboru sposobu pracy i testowanych kwantów.

## Praca automatyczna

Praca automatyczna umożliwia uruchomienie programu na komputerze bez podłączonego terminala.

**UWAGA:** Wadliwa praca modułu lub kwantu może w szczególnych przypadkach powodować,
że przy pracy w pełni automatycznej nie zostanie on ujęty w teście i uszkodzenie nie
zostanie zaraportowane.

### Raportowanie błędów

Jeśli w trakcie pracy bez terminala napotkany zostanie błąd pamięci, program zatrzymuje się ze stopem `HLT 077`. Z rejestrów można wtedy odczytać opis błędu:

 * `r1` - krok MARCH C- (1-6)
 * `r2` - moduł (bity 9-12) i kwant (bity 13-15) pamięci
 * `r3` - adres
 * `r4` - odczytana wartość
 * `r5` - spodziewana wartość
 * `r0` bit `15` - zapalony oznacza błąd parzystości

Opuszczenie i ponowne podniesienie klucza `START` kontynuuje test.

## Praca konwersacyjna

### Start programu

Po uruchomieniu w trybie konwersacyjnym
test sprawdza konfigurację pamięci i wyświetla
mapę kwantów pamięci podstawowej:

```
Test pamieci MARCH C-
------------------------------------------
Strony systemowe: 2
Pamiec MEGA (Amepol): NIE
Pamiec Computex: NIE
Mapa kwantow pamieci standardowej:

[S] systemowy  [+] dostepny  [_] brak  [?] brak odp. r/w  [X] pusty odczyt

   01234567   01234567   01234567   01234567
 0 SS++++++ 1 ++++++++ 2 ________ 3 ________
 4 ________ 5 ________ 6 ________ 7 ________
 8 ________ 9 ________ a ________ b ________
 c ________ d ________ e ________ f ________
```

 * `S` - kwant systemowy, skonfigurowany na stałe
 * `_` - żaden moduł pamięci nie odpowiedział na próbę konfiguracji kwantu
 * `?` - próba zapisu/odczytu pod adres `0` w kwancie zakończyła się brakiem odpowiedzi
 * `X` - odczyt spod adresu `0` w kwancie zwrócił "puste" dane:
         same "0" bez błędu parzystości lub same "1" z błędem parzystości
 * `+` - kwant dostępny, możliwy do użycia

**UWAGA:** Przy pracy automatycznej do testu wybierane są tylko kwanty, które zostały rozpoznane jako dostępne (`+`).

### Menu

Następnie program wyświetla menu i oczekuje na polecenie użytkownika:

```
 <L> Zapetlanie testu          <S> Stop po bledzie
 <T> Test dostepnych kwantow   <K> Test wybranego kwantu
 <M> Test wybranego modulu     <P> Pokaz mape pamieci
 Dowolny inny klawisz - pokaz menu
```

Naciśnięcie klawisza wybiera funkcję:

 * `L` - przełączenie pomiędzy testem zapętlonym a pojedynczym (domyślnie pojedynczy)
 * `S` - przełączenie pomiędzy zatrzymywaniem pracy po napotkaniu błędu lub pracą ciągłą (domyślnie ciagła)
 * `T` - uruchomienie testu wszystkich dostępnych kwantów - odpowiednik uruchomienia testu w trybie pracy w pełni automatycznej
 * `K` - wybranie pojedynczego kwantu i uruchomienie testu tylko dla niego
 * `M` - wybranie pojedynczego modułu (7 kwantów) i uruchomienie testu tylko dla niego
 * `P` - ponowne wyświetlenie mapy pamięci
 * dowolny inny klawisz wyświetla ponownie menu

### Działanie testu i raportowanie błędów

W trakcie działania testu możliwe jest jego przerwanie w dowolnej chwili przez naciśnięcie klawisza `X`.

Napotkanie błędu powoduje wyświetlenie jego opisu, np.:

```
uR0W1 1 5 001e 0001
```

Kolejne pozycje opisu odddzielone spacjami to:

 * Krok MARCH C-:
   * `u/d` - rosnące/malejące adresy,
   * `R/W` - zapisywana/odczytywana wartość,
   * `0/1` - zapis bądź spodziewany odczyt: "0" lub "1",
   * `-` na pozycji wartości oznacza, że wartość nie jest używana w kroku
 * numer modułu
 * numer kwantu
 * adres
 * odczytana wartość

Przykładowy błąd powyżej oznacza więc:
 * Krok MARCH C-: adresy rosnąco, spodziewany odczyt "0", zapis "1"
 * moduł 1, kwant 5, adres 0x001e
 * odczytana wartość `0x0001` (podczas gdy spodziewana była `0x0000`)

Jeśli test działa w trybie z zatrzymywaniem po napotkaniu błędu wyświetlana jest również zachęta pozwalająca kontynuować test (klawisz `ENTER`), bądź przerwać go (klawisz `X`).

## Kody stopów programu

Wspomniany wcześniej stop `HLT 077` jest tylko jednym z możliwych zatrzymań programu:

| Kod | Znaczenie |
|-----|-----------|
| 010 | Zajętość przy konfigurowaniu pamięci |
| 011 | Błąd parzystości przy konfigurowaniu |
| 015 | Brak odpowiedzi podczas konfigurowania pamięci do testu |
| 016 | Brak odpowiedzi podczas dekonfigurowania pamięci po teście |
| 020 | Brak odpowiedzi z terminala podczas wysyłania znaku |
| 021 | Brak odpowiedzi z terminala podczas czytania znaku |
| 030 | Brak odpowiedzi na konfigurację pamięci w procesie sprawdzania segmentów systemowych |
| 031 | Brak odpowiedzi na dekonfigurację pamięci w procesie sprawdzania segmentów systemowych |
| 032 | Zajętość bądź błąd parzystości podczas sprawdzania pamięci Computex-u |
| 033 | Zajętość bądź błąd parzystości podczas sprawdzania pamięci MEGA Amepolu |
| 045 | Błąd dostępu do pamięci podczas testu (przerwanie brak pamięci) |
| 046 | Niespodziewane przerwanie |
| 077 | Zatrzymanie na błędzie pamięci podczas testu MARCH C- bez terminala |
