package com.farmos.farmos.service;

import com.farmos.farmos.model.Plot;

import java.util.List;

public interface PlotService {

    List<Plot> getPlotsByFarm(Long farmId);

    Plot createPlot(Long farmId, Plot plot);

    Plot updatePlot(Long farmId, Long plotId, Plot updatedPlot);

    void deletePlot(Long plotId);
}
