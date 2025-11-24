package com.acme;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.stream.Stream;

public class AlgoService {
  static record InferRequest(List<Float> x, Float scale) {}
  static record InferResponse(List<Float> y, String algoVersion, long elapsedNs) {}

  public static void main(String[] args) throws Exception {
    String inputDir = System.getenv().getOrDefault("INPUT_DIR", "/rundata/input");
    String outputDir = System.getenv().getOrDefault("OUTPUT_DIR", "/rundata/output");
    String algoVersion = System.getenv().getOrDefault("ALGO_VERSION", "0.1.0");
    
    var om = new ObjectMapper();
    Path inputPath = Paths.get(inputDir);
    Path outputPath = Paths.get(outputDir);
    
    // Ensure output directory exists
    Files.createDirectories(outputPath);
    
    // Check if input directory exists
    if (!Files.exists(inputPath) || !Files.isDirectory(inputPath)) {
      System.err.println("ERROR: Input directory does not exist: " + inputDir);
      System.exit(1);
    }
    
    // Process all JSON files in input directory
    try (Stream<Path> paths = Files.list(inputPath)) {
      List<Path> inputFiles = paths
        .filter(Files::isRegularFile)
        .filter(p -> p.toString().endsWith(".json"))
        .toList();
      
      if (inputFiles.isEmpty()) {
        System.out.println("INFO: No JSON files found in input directory: " + inputDir);
        System.exit(0);
      }
      
      System.out.println("INFO: Processing " + inputFiles.size() + " file(s) from " + inputDir);
      
      for (Path inputFile : inputFiles) {
        try {
          // Read input file
          String content = Files.readString(inputFile);
          InferRequest req = om.readValue(content, InferRequest.class);
          
          // Convert to float array
          float[] in = new float[req.x().size()];
          for (int i = 0; i < req.x().size(); i++) {
            in[i] = req.x().get(i);
          }
          float scale = req.scale() == null ? 1.0f : req.scale();
          
          // Process with native kernel
          long t0 = System.nanoTime();
          float[] out = NativeKernels.fastOp(in, scale);
          long dt = System.nanoTime() - t0;
          
          // Convert output to list
          var y = new java.util.ArrayList<Float>();
          for (float val : out) {
            y.add(val);
          }
          
          // Create response
          InferResponse response = new InferResponse(y, algoVersion, dt);
          
          // Write output file (same name as input)
          String outputFileName = inputFile.getFileName().toString();
          Path outputFile = outputPath.resolve(outputFileName);
          String outputJson = om.writerWithDefaultPrettyPrinter().writeValueAsString(response);
          Files.writeString(outputFile, outputJson);
          
          System.out.println("INFO: Processed " + inputFile.getFileName() + 
                           " -> " + outputFile.getFileName() + 
                           " (elapsed: " + dt + " ns)");
        } catch (Exception e) {
          System.err.println("ERROR: Failed to process " + inputFile.getFileName() + ": " + e.getMessage());
          e.printStackTrace();
          System.exit(1);
        }
      }
      
      System.out.println("INFO: Successfully processed all files. Exiting.");
    }
  }
}