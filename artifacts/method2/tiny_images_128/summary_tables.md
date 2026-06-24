# VGG11 Tiny Images Cluster Benchmark Summary
## Dataset
- Dataset: `data/vgg11-tiny-images-128`
- Images: 4 public images (`bus`, `zidane`, `dog`, `fruits`)
- Image size: `128x128` RGB PPM
- Model: torchvision pretrained VGG11 without BatchNorm
- Cluster: 3 MacBooks, weighted hostfile `4/6/2` for 12-rank run

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
| 1 | 1x1 | 6.297 | 1.000 | 1.000 | 0.000 | YES |
| 2 | 1x2 | 3.369 | 1.869 | 0.935 | 0.000 | YES |
| 4 | 2x2 | 1.943 | 3.241 | 0.810 | 0.000 | YES |
| 8 | 2x4 | 65.466 | 0.096 | 0.012 | 0.625 | YES |
| 12 | 3x4 | 95.005 | 0.066 | 0.006 | 0.552 | YES |

## P=12 Rank Time Breakdown
| Rank | Host | Scatter (s) | Halo (s) | Compute (s) | Gather (s) | Total (s) | Idle (s) |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | Phams-MB-Air | 0.205 | 5.790 | 0.743 | 17.814 | 24.552 | 1.529 |
| 1 | Phams-MB-Air | 0.000 | 6.294 | 0.743 | 18.048 | 25.085 | 0.996 |
| 2 | Phams-MB-Air | 0.000 | 6.774 | 0.734 | 15.541 | 23.050 | 3.031 |
| 3 | Phams-MB-Air | 0.000 | 6.815 | 0.733 | 18.534 | 26.081 | 0.000 |
| 4 | MB-Pro-M4-Pro | 0.008 | 4.429 | 0.589 | 12.414 | 17.439 | 8.642 |
| 5 | MB-Pro-M4-Pro | 0.076 | 4.118 | 0.592 | 16.773 | 21.560 | 4.521 |
| 6 | MB-Pro-M4-Pro | 0.056 | 4.038 | 0.591 | 13.612 | 18.297 | 7.784 |
| 7 | MB-Pro-M4-Pro | 0.184 | 3.971 | 0.591 | 13.118 | 17.863 | 8.218 |
| 8 | MB-Pro-M4-Pro | 0.186 | 4.567 | 0.540 | 14.582 | 19.875 | 6.206 |
| 9 | MB-Pro-M4-Pro | 1.600 | 3.205 | 0.540 | 16.787 | 22.132 | 3.949 |
| 10 | Nguyens-MB-Air-5 | 0.217 | 2.995 | 0.846 | 11.142 | 15.200 | 10.881 |
| 11 | Nguyens-MB-Air-5 | 0.232 | 3.314 | 0.847 | 16.901 | 21.294 | 4.787 |

## Figures
- `figures/vgg11_conv_method2.png`
- `figures/vgg11_rank_metrics_p12.png`

## Interpretation
- P=1 -> P=4 improves runtime, so the distributed convolution implementation works and can exploit parallel compute.
- P=8 and P=12 become much slower because the image is small and many blocks cross machine boundaries, so halo exchange and gather dominate.
- This is useful evidence for the report: fine-grained data parallelism requires enough input size per rank; otherwise communication dominates computation.
