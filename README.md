**English** | [Русский](#russian)

# Power: horizontal battery for the Omarchy bar

A drop-in replacement for Omarchy's built-in power widget (`omarchy.power`) that
draws the battery **horizontally** and puts the remaining charge **to the right
of the icon**.

![The battery in the bar](preview.png)

- **Horizontal icon.** Material's `md-battery` glyphs are vertical, so the glyph
  is turned a quarter turn: the terminal ends up on the right and the charge
  fills from the left, like a real battery.
- **Ten levels.** The stock `md-battery` set is kept, so the icon steps through
  ten fill levels rather than five.
- **Charge to the right.** `88%` is drawn after the icon at the bar's body size
  (`Style.font.body`), not inside the rotated glyph.
- **Bolt on the left.** While charging, the bolt is its own glyph to the left of
  the battery instead of being part of the `md-battery_charging_*` set, which
  drew it under the battery.
- **Bigger icon.** The battery is drawn at 1.5× the bar's icon size
  (`Style.bar.iconFont * 1.5` in a `Style.bar.iconCanvas * 1.5` box).
- **Red under 10%.** Below a tenth of a charge the icon takes the theme's urgent
  colour; the percentage keeps the normal foreground.
- **Right-click** toggles the percentage on and off; the choice is kept in
  `shell.json` as `showPercentage`.
- **Russian labels** in the panel: `От батареи`, `Зарядка`, `Порог`,
  `Полностью заряжена`, plus the charging phrases.

## Install

```bash
omarchy plugin add https://github.com/Mystical89/myomarchy-power.git --enable
```

The widget is added once; enable the percentage in the bar settings panel.

## Settings

| Key | Default | Meaning |
|---|---|---|
| `showPercentage` | `false` | Draw the charge next to the icon (right-click toggles it) |

Everything else — the panel with the power profile, the battery stats, the
low-charge threshold handling — is Omarchy's own code, unchanged.

## Uninstall

```bash
omarchy plugin remove mystical.power
```

Because the manifest records `clonedFrom: omarchy.power`, removing this plugin
lets Omarchy re-enable its stock widget. The bar entry stays in `shell.json`.

## How it differs from omarchy.power

| File | Change |
|---|---|
| `Panel.qml` | `BarIconButton` → `WidgetButton` with a `Row`: the rotated `OpticalGlyph` plus a `Text` for the charge. The stock code builds one string (`"88% 󰁹"`) for the glyph, which cannot work once the icon is rotated — the text would rotate too. |
| `Panel.qml` | The glyph gets `rotation: 90` inside a `Style.bar.iconCanvas` box at `Style.bar.iconFont`; the charge is drawn at `Style.font.body`; spacing and padding come from `Style.space()`. |
| `Panel.qml` | `moduleName` / `ipcTarget` are `mystical.power` instead of `omarchy.power`: right-click writes `showPercentage` into this plugin's own bar entry, and the IPC handler no longer collides with the stock widget's. |
| `Model.js` | `batteryIcon()` returns the plain ten-level set only — the charging variants moved out to a separate bolt — and the mode labels are Russian. |

## Keeping up with upstream

`omarchy.power` ships inside the Omarchy package, so there is no repository to
`git pull` from. `tools/merge-upstream.sh` does a three-way merge instead: it
fetches upstream as it was when this fork was made (recorded in
`.upstream-base`), fetches current upstream from `omacom/omarchy`, and merges
both into the working tree while keeping the fork's own edits.

```bash
tools/merge-upstream.sh            # has upstream moved? no writes
tools/merge-upstream.sh --apply    # merge, write files, bump .upstream-base
tools/merge-upstream.sh --keep     # leave merged files in a temp dir for review
tools/merge-upstream.sh --ref SHA  # merge up to a specific upstream commit
```

Conflicts are printed and nothing is written: keep this fork's structure and
take upstream's values (`target: heroStatus` stays, durations come from
upstream). After `--apply`, run `omarchy restart shell` — QML does not
hot-reload for panels, so an un-restarted shell keeps showing the old code.
`manifest.json` is never merged; the fork owns it.

## License

MIT — see [LICENSE](LICENSE). The original widget is Omarchy's, copyright
David Heinemeier Hansson.

---

<a id="russian"></a>

## Русский

[↑ English](#power-horizontal-battery-for-the-omarchy-bar)

Замена штатного виджета питания Omarchy (`omarchy.power`): батарея рисуется
**горизонтально**, а остаток заряда выводится **справа от иконки**.

![Батарея в баре](preview.png)

- **Горизонтальная иконка.** Глифы `md-battery` в Material вертикальные, поэтому
  глиф поворачивается на четверть оборота: контакт оказывается справа, а заряд
  заполняется слева — как у настоящей батареи.
- **Десять уровней.** Штатный набор `md-battery` сохранён, так что иконка
  проходит десять ступеней заполнения, а не пять.
- **Заряд справа.** `88%` рисуется после иконки кеглем тела бара
  (`Style.font.body`), а не внутри повёрнутого глифа.
- **Молния слева.** Во время зарядки молния рисуется отдельным глифом слева от
  батареи, а не берётся из набора `md-battery_charging_*`, который рисовал её
  под батареей.
- **Иконка крупнее.** Батарея рисуется в 1,5 раза крупнее иконок бара
  (`Style.bar.iconFont * 1.5` в канве `Style.bar.iconCanvas * 1.5`).
- **Красная ниже 10%.** Когда заряда меньше десятой части, иконка берёт
  urgent-цвет темы; проценты остаются обычного цвета.
- **Правый клик** включает и выключает проценты; выбор сохраняется в
  `shell.json` как `showPercentage`.
- **Русские подписи** в панели: `От батареи`, `Зарядка`, `Порог`,
  `Полностью заряжена`, а также фразы про зарядку.

### Установка

```bash
omarchy plugin add https://github.com/Mystical89/myomarchy-power.git --enable
```

Виджет добавляется один раз; включите проценты в панели настроек бара.

### Настройки

| Ключ | По умолчанию | Смысл |
|---|---|---|
| `showPercentage` | `false` | Рисовать заряд рядом с иконкой (правый клик переключает) |

Всё остальное — панель с профилем питания, статистика батареи, обработка порога
низкого заряда — это код Omarchy без изменений.

### Удаление

```bash
omarchy plugin remove mystical.power
```

Так как в манифесте указано `clonedFrom: omarchy.power`, после удаления Omarchy
снова включит свой штатный виджет. Запись в баре остаётся в `shell.json`.

### Чем отличается от omarchy.power

| Файл | Изменение |
|---|---|
| `Panel.qml` | `BarIconButton` → `WidgetButton` с `Row`: повёрнутый `OpticalGlyph` плюс `Text` для заряда. Штатный код собирает одну строку (`"88% 󰁹"`) для глифа, что невозможно, когда иконка повёрнута — текст повернулся бы вместе с ней. |
| `Panel.qml` | Глиф получает `rotation: 90` в канве `Style.bar.iconCanvas` размером `Style.bar.iconFont`; заряд рисуется кеглем `Style.font.body`; отступы — из `Style.space()`. |
| `Panel.qml` | `moduleName` / `ipcTarget` — `mystical.power`, а не `omarchy.power`: правый клик пишет `showPercentage` в запись именно этого плагина, а IPC-обработчик больше не конфликтует со штатным виджетом. |
| `Model.js` | `batteryIcon()` возвращает только обычный набор из десяти уровней — зарядные варианты вынесены в отдельную молнию, — а подписи режима по-русски. |

### Обновление из апстрима

`omarchy.power` лежит внутри пакета Omarchy, отдельного репозитория у него нет,
поэтому `git pull` здесь не работает. `tools/merge-upstream.sh` делает
трёхсторонний мерж: берёт апстрим на момент создания форка (записан в
`.upstream-base`), берёт текущий апстрим из `omacom/omarchy` и сливает оба с
локальными правками.

```bash
tools/merge-upstream.sh            # изменился ли апстрим? ничего не пишет
tools/merge-upstream.sh --apply    # слить, записать файлы, обновить .upstream-base
tools/merge-upstream.sh --keep     # оставить результат мержа во временном каталоге
```

Конфликты печатаются, файлы не перезаписываются: держи структуру форка, бери
значения апстрима. После `--apply` — `omarchy restart shell`: QML панелей не
перезагружается на лету, и без рестарта видно старый код. `manifest.json` не
мержится, им владеет форк.

### Лицензия

MIT — см. [LICENSE](LICENSE). Исходный виджет принадлежит Omarchy, copyright
David Heinemeier Hansson.
