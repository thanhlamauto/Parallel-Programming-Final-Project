# VGG11 Method 2 N=224 Speedup Summary
## Correctness and Classifier
| Metric | Value |
| --- | --- |
| Distributed top-1 | 951 (lemon) |
| Serial top-1 | 951 (lemon) |
| Top-1 match | YES |
| Logit max error | 0.000000 |

## Speedup Sweep
| P | Grid | Runtime (s) | Speedup | Efficiency | Inter-machine halo ratio | Correct |
| ---: | --- | ---: | ---: | ---: | ---: | --- |
| 1 | 1x1 | 20.689 | 1.000 | 1.000 | 0.000 | YES |
| 2 | 1x2 | 10.809 | 1.914 | 0.957 | 0.000 | YES |
| 4 | 2x2 | 5.797 | 3.569 | 0.892 | 0.000 | YES |
| 8 | 2x4 | 115.315 | 0.179 | 0.022 | 0.625 | YES |
| 12 | 3x4 | 170.805 | 0.121 | 0.010 | 0.552 | YES |

## Figures
- `figures/vgg11_conv_method2.png`
- `figures/vgg11_rank_metrics_p12.png`
- `figures/with_without_communication.png`
