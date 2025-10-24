package com.acme;

import io.javalin.Javalin;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.util.List;

public class AlgoService {
  static record InferRequest(List<Float> x, Float scale) {}
  static record InferResponse(List<Float> y, String algoVersion) {}

  public static void main(String[] args) throws Exception {
    var app = Javalin.create(cfg -> cfg.http.defaultContentType = "application/json");
    var om = new ObjectMapper();

    app.get("/health/ready", ctx -> ctx.result("ok"));
    app.get("/health/live",  ctx -> ctx.result("ok"));
    app.get("/version", ctx -> ctx.json(Map.of(
      "service","algosvc","algoVersion","0.1.0","libPath","/app/lib/libkernels.so")));

    app.post("/infer", ctx -> {
      var req = om.readValue(ctx.body(), InferRequest.class);
      float[] in = new float[req.x().size()];
      for (int i=0;i<req.x().size();i++) in[i] = req.x().get(i);
      float scale = req.scale() == null ? 1.0f : req.scale();
      long t0 = System.nanoTime();
      float[] out = NativeKernels.fastOp(in, scale);
      long dt = System.nanoTime() - t0;
      ctx.header("x-elapsed-ns", Long.toString(dt));
      var y = new java.util.ArrayList<Float>();
      for (float val : out) y.add(val);
      ctx.json(new InferResponse(y, "0.1.0"));
    });

    int port = Integer.parseInt(System.getenv().getOrDefault("PORT","8080"));
    app.start(port);
  }
}