package com.acme;
public class NativeKernels {
  static { System.load("/app/lib/libkernels.so"); }
  public static native float[] fastOp(float[] in, float scale);
}