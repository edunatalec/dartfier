# dartfier — contrato

Pacote de reatividade fine-grained para Flutter, construído inteiramente sobre `ChangeNotifier`/`ValueListenable`. Nasceu como projeto de estudo do modelo de auto-tracking (Preact Signals/MobX) e como candidato a substituir primitivas do `lune_foundation` (`ValueStore`, `ObserverWidget` e os `Listenable.merge` manuais) — promoção condicionada a piloto num módulo de app real.

## Modelo

**Push-dirty, pull-compute.** Escrever num `Signal` propaga *sujeira* (dirty) e notificação pelos dependentes; o **recálculo** só acontece na **leitura**. Consequências:

- **Leituras são sempre consistentes.** Qualquer leitura após qualquer notificação recalcula com o estado corrente — inclusive em grafos diamante (A alimenta B e C; D lê B e C): D notifica **uma vez** e lê consistente.
- **Notificações podem ser espúrias.** Um `Computed` notifica ao ficar dirty, antes de saber se o novo resultado difere do anterior. Widgets absorvem isso (rebuild coalescido por frame); listeners manuais devem tolerar notificação sem mudança de valor.

**Tracking por leitura.** O getter `.value` de `Signal` e `Computed` reporta a leitura ao escopo de tracking corrente (builder de `Observer`, função de `Computed` ou corpo de `Effect` em execução). O conjunto de dependências é **redescoberto a cada execução** — ramos condicionais inscrevem exatamente o que foi lido na última execução. Cada camada se inscreve um nível abaixo: um `Observer` que lê um `Computed` se inscreve no `Computed`, não nos `Signal`s internos dele.

**Efeitos coalescem por microtask.** A primeira execução de um `Effect` é síncrona (na criação, para coletar as dependências). Re-execuções são agendadas no fim da fila de microtasks: uma rajada de escritas síncronas produz **uma** re-execução, que lê estado consistente — efeito não observa glitch de diamante.

## API

| Tipo | Contrato |
|---|---|
| `Signal<T>` | `ChangeNotifier` + `ValueListenable<T>`. Setter com guard de igualdade (`==`) e de dispose. Getter reporta leitura ao tracker. |
| `Computed<T>` | Lazy: primeira leitura computa; leituras seguintes retornam cache até uma dependência notificar. Dirty não re-notifica enquanto já dirty. Ciclo de dependência lança `StateError`. Após `dispose`, para de reagir; leitura com cache sujo recalcula uma vez sem se inscrever, e disposto limpo congela no último valor. Exceção no compute propaga na leitura, mantém o dirty e não inscreve as deps parciais — a próxima leitura recalcula. |
| `Effect` | Roda síncrono na criação; re-executa coalescido por microtask quando uma dependência notifica. `dispose()` cancela re-execuções pendentes e futuras. Exceção na primeira execução propaga do construtor; numa re-execução vira erro assíncrono da `Zone`. Não é `Listenable` — ninguém observa um efeito. |
| `Observer` | `StatefulWidget`; `Observer((context) => ...)` roda o builder sob tracking e rebuilda quando qualquer valor lido notificar. Descarta as inscrições no `dispose`. |

## Limitações deliberadas (v1)

- **Sem `batch`, coleções observáveis e `watch()` para `Listenable` alheio** — entram se a prática pedir.
- **Compute e effect síncronos por contrato** — `await` quebra o tracking (limitação estrutural do modelo; mesma do MobX).
- **Closures adiadas não trackeiam** — só o corpo síncrono do builder/compute/effect inscreve.
- **`Effect` que escreve na própria dependência**: na primeira execução a escrita cai no vazio (as inscrições são feitas depois que o corpo roda) e não gera re-execução; a partir de uma re-execução, re-agenda para sempre — sem guard de loop no v1; responsabilidade do chamador.
- **Sem lint** — as regras acima são verificadas por teste e disciplina, não por analyzer.
