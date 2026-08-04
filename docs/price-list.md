# GET /api/v2/accounts/{id}/plan

Retorna a lista de preços (plano tarifário) vigente de uma conta, incluindo valores recorrentes (`billingEvents`) , os modificadores de preço resolvidos (padrão por origem de eventos ou sobrescritos enviados na query).

## Autenticação e autorização

| Camada | Mecanismo | Falha |
|---|---|---|
| Autenticação | JWT Bearer validado via Auth0 (`checkAuthentication`) | `401 Unauthorized` |
| Autorização | Permissão `read:plan` deve estar entre as permissions do token (`checkAuthorization`) | `401 Unauthorized` |

## Requisição

```
GET /api/v2/accounts/{id}/plan?scope={scope}&parameters={parameters}
Authorization: Bearer <token>
```

### Path parameters

| Nome | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | string (ObjectID hex, 24 chars) | Sim | Id da conta. Qualquer valor com tamanho diferente de 24 resulta em `400`. |

### Query parameters

| Nome | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `scope` | string | Não | Id de um escopo de faturamento. Quando informado, os plano vigente pode ser específico desse escopo, e não o plano vinculado diretamente à conta. |
| `parameters` | string (JSON) | Não | Array serializado em JSON com overrides de modificadores por origem de eventos. Ver [formato de `parameters`](#formato-de-parameters). Um JSON malformado resulta em `400`. |

#### Formato de `parameters`

```json
[
  { "event": "pedidos-entregues", "modifiers": ["campanha", "semana-do-ano"] }
]
```


| Campo | Tipo | Descrição |
|---|---|---|
| `event` | string | Nome da origem de eventos ao qual os modificadores se aplicam. |
| `modifiers` | string[] | Valores, ordenados dos campos definidos com a função `modifier` no mapeamento de campos da origem de eventos. |

Uma eventual lista de modificadores enviados **só substituem** os defaults quando a lista tiver o mesmo tamanhoda lista de defaults para aquele evento; caso contrário os defaults da origem de eventos prevalecem.

## Resposta

### 200 OK

Corpo JSON (indentado com 2 espaços):

```json
{
  "accountId": "64b1f1f1f1f1f1f1f1f1f1f1",
  "accountName": "Acme Corp",
  "planId": "64b1f1f1f1f1f1f1f1f1f1f2",
  "events": [
    {
      "realm": "plataforma-x",
      "event": "pedidos-entregues",
      "eventModifiers": {
        "names": ["campanha", "week"],
        "values": ["campanha-xyz", "2026-32"]
      },
      "parameters": {
        "values": ["campanha-abc", "2026-30"]
      },
      "services": [
        {
          "serviceId": "64b1f1f1f1f1f1f1f1f1f1f3",
          "realmServiceId": "mac-lanche-super-feliz",
          "modifiers": "*|2026-32",
          "unitaryPrice": 0.15,
          "faceValue": 0.2
        }
      ]
    }
  ],
  "billingEvents": [
    {
      "realm": "ocs",
      "event": "recurrent-fee",
      "serviceId": "64b1f1f1f1f1f1f1f1f1f1f4",
      "unitaryPrice": 99.9
    }
  ]
}
```

Campos (`AccountPlanNew` / `EventsPlanNew` / `EventModifiers` / `ParametersValues` / `ServicesPlanNew` / `BillingServicesPlan`):

| Campo | Tipo | Descrição |
|---|---|---|
| `accountId` | string (ObjectID) | Id da conta. |
| `accountName` | string | Nome da conta. |
| `planId` | string (ObjectID) | Id do plano vigente aplicado. |
| `events[]` | array | Origens de eventos do plano, com preços resolvidos. |
| `events[].realm` | string | Origem do evento (ex: plataforma). |
| `events[].event` | string | Nome do evento. |
| `events[].eventModifiers.names` | string[] | Nomes dos campos modificadores ordenados (serão avaliados quanto a especificidade nesta ordem). |
| `events[].eventModifiers.values` | string[] | Valores finais dos modificadores — vindos do `parameters` da query quando aplicável (ver regra acima), ou os defaults da origem. |
| `events[].parameters.values` | string[] | Eco dos valores dos valores enviados na query para este evento (vazio se nenhum foi enviado). |
| `events[].services[]` | array | Uma entrada por serviço aplicável por origem. |
| `events[].services[].serviceId` | string | Id do serviço . |
| `events[].services[].realmServiceId` | string | Id do serviço na origem (SKU). |
| `events[].services[].modifiers` | string | Id do modificador utilizado (* para a regra padrão, não houve match com nenhum valor de modifificador cadastrado). |
| `events[].services[].unitaryPrice` | number | Preço unitário do serviço (`realmServices.modifiers.services.value`). |
| `events[].services[].faceValue` | number | Valor de face do serviço (`services.custom.faceValue`). |
| `billingEvents[]` | array | Valores aplicados a fatura final (recorrentes ou não). |
| `billingEvents[].serviceId` | string (ObjectID) | Identificador do serviço de fatura. |
| `billingEvents[].unitaryPrice` | number | Valor do serviço de fatura. |

### Erros

| Status | Causa |
|---|---|
| `400 Bad Request` | `id` ausente ou com tamanho diferente de 24 caracteres; ou `parameters` presente mas não é um JSON válido. |
| `401 Unauthorized` | Token ausente/inválido; ou token válido sem a permissão `read:plan`. |
| `404 Not Found` | `id` não é um ObjectID válido/existente; ou a conta não possui plano vigente (`from <= agora <= to`); ou (quando `scope` é informado) e não há plano específico associado a este escopo de faturamento. |
| `500 Internal Server Error` | Erro inesperado de banco de dados ou falha ao serializar a resposta. |

## Exemplo de chamada

```
GET /api/v2/accounts/64b1f1f1f1f1f1f1f1f1f1f1/plan?scope=64b1f1f1f1f1f1f1f1f1f1f2&parameters=%5B%7B%22event%22%3A%22call%22%2C%22modifiers%22%3A%5B%22SP%22%2C%221%22%5D%7D%5D
Authorization: Bearer <token>
```

`parameters` decodificado: `[{"event":"pedidos-entregues","modifiers":["campanha-abc", "2026-30"]}]`
