# PR: Add gemma4:e4b Model to OpenClaw Agents Cluster

## Summary
This PR adds the `gemma4:e4b` model to the OpenClaw agents cluster configuration as a new available model for agent inference.

## Changes

### ConfigMap: openclaw-config.yaml
- Added `gemma4:e4b` to the model catalog (available models)
- Set as the default primary model for all agents
- Configured fallbacks to ensure availability if primary model is unavailable

## Model Details

| Property | Value |
|----------|-------|
| Model Name | gemma4:e4b |
| Provider | Ollama |
| Type | LLM |
| Deployment | Local cluster deployment |

## Testing
- Verify ConfigMap is mounted correctly in agent pods
- Confirm model appears in agent's model catalog
- Test model routing and fallback behavior

## Related
- Cluster configuration documentation
- Model deployment guidelines
