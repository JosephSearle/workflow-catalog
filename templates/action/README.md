# __NAME__

One sentence describing what the action does.

## Usage

Inside a catalog workflow, after checking out the catalog to `.catalog`:

```yaml
- uses: ./.catalog/actions/__NAME__
  with:
    example-input: value
```

From any other repo:

```yaml
- uses: JosephSearle/workflow-catalog/actions/__NAME__@v1
```

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `example-input` | no | `value` | What this input controls. |

## Outputs

| Name | Description |
| --- | --- |
| `example-output` | What this output contains. |

## Supported runners

ubuntu
