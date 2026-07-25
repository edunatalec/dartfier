# dartfier

Reatividade fine-grained sobre `ChangeNotifier`: `Signal`, `Computed`, `Effect` e o widget `Observer` com auto-tracking. Zero dependências além do Flutter, sem codegen, interop total com `ValueListenable`.

O contrato completo de semântica vive em [`docs/product.md`](docs/product.md).

## Uso

```dart
final Signal<int> count = Signal(0);
final Computed<int> doubled = Computed(() => count.value * 2);

Observer((context) => Text('${count.value} × 2 = ${doubled.value}'))

final Effect logger = Effect(() => debugPrint('count: ${count.value}'));
```

- **`Signal<T>`** — valor reativo. Ler `.value` dentro de um contexto trackeado (builder do `Observer`, função de um `Computed` ou corpo de um `Effect`) inscreve o leitor automaticamente; escrever notifica (com guard de igualdade e de dispose).
- **`Computed<T>`** — derivado auto-trackeado e lazy: só recalcula na leitura, cacheia entre leituras e redescobre as dependências a cada recálculo (leituras condicionais funcionam).
- **`Effect`** — efeito colateral reativo: roda na criação e re-executa quando qualquer valor lido mudar. Re-execuções são coalescidas por microtask — uma rajada de escritas síncronas vira uma execução só, lendo estado consistente.
- **`Observer`** — roda o `builder(context)` sob tracking e rebuilda quando qualquer valor lido mudar. Sem lista de listenables, sem `Listenable.merge`.

Como `Signal` e `Computed` implementam `ValueListenable<T>`, tudo interopera com `ValueListenableBuilder`, `Listenable.merge` e qualquer API do Flutter que aceite `Listenable`.

## Regras de uso

1. **Função de `Computed` e corpo de `Effect` são síncronos.** Um `await` perde o contexto de tracking — leituras depois dele não registram dependência. O tipo (`T Function()`) já barra `async`; não contorne com `.then`.
2. **Leia `.value` diretamente no builder do `Observer`.** Closures que rodam depois (um `Builder` aninhado, um callback de gesto) executam fora do tracking e não inscrevem — para reagir, o valor precisa ser lido no corpo do builder.
3. **`Effect` não escreve nas próprias dependências.** Um efeito que escreve num `Signal` que ele mesmo lê re-agenda para sempre a partir da primeira re-execução.
4. **Dispose é seu.** `Signal`, `Computed` e `Effect` têm dono: quem cria, descarta.
