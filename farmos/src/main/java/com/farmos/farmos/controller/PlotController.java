package com.farmos.farmos.controller;

import com.farmos.farmos.model.Plot;
import com.farmos.farmos.service.PlotService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
@RequestMapping("/api/farms/{farmId}/plots")
public class PlotController {

    private final PlotService plotService;

    public PlotController(PlotService plotService) {
        this.plotService = plotService;
    }

    @GetMapping
    public List<Plot> getPlots(@PathVariable Long farmId) {
        return plotService.getPlotsByFarm(farmId);
    }
    @PutMapping("/{plotId}")
    public ResponseEntity<Plot> updatePlot(
            @PathVariable Long farmId,
            @PathVariable Long plotId,
            @RequestBody Plot plot) {
        return ResponseEntity.ok(plotService.updatePlot(farmId, plotId, plot));
    }
    

    @PostMapping
    public ResponseEntity<Plot> createPlot(
            @PathVariable Long farmId,
            @RequestBody Plot plot) {
        return ResponseEntity.ok(plotService.createPlot(farmId, plot));
    }

    @DeleteMapping("/{plotId}")
    public ResponseEntity<Void> deletePlot(
            @PathVariable Long farmId,
            @PathVariable Long plotId) {
        plotService.deletePlot(plotId);
        return ResponseEntity.ok().build();
    }
}