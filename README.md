# Flint 2 VPN domains

Список доменов для выборочной маршрутизации через VPN на GL.iNet Flint 2.

Готовая ссылка для поля **Subscription URL**:

```text
https://raw.githubusercontent.com/digiden96/flint2-vpn-domains/main/domains.txt
```

## Как использовать

1. В GL.iNet откройте **VPN → VPN Dashboard**.
2. Для туннеля выберите **Specified Domain / IP List**.
3. Добавьте указанную выше ссылку как **Subscription URL**.
4. Оставьте **Allow Non-VPN Traffic** включённым.
5. Устройства должны использовать DNS роутера (`192.168.50.1`), а Secure DNS/DoH в браузере следует отключить.

В результате домены из `domains.txt` идут через VPN, а остальной трафик, включая соединения с торрент-пирами по IP, — напрямую через провайдера.

## Как добавить домен

Добавьте его отдельной строкой в `custom-domains.txt`, без `https://`, путей и `*.`. Например:

```text
example.com
```

Файл `domains.txt` автоматически обновляется ежедневно. Источник основного списка — [itdoginfo/allow-domains](https://github.com/itdoginfo/allow-domains).

