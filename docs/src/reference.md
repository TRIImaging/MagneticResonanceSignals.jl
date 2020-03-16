# API Reference

## MR data types

```@docs
MRExperiment
MagneticResonanceSignals.PRESS
MagneticResonanceSignals.LCOSY
```

## Querying MR data

```@docs
meta_search
standard_metadata
scanner_time
sampledata
count_cycles
```

## High level file IO and conversion

```@docs
mr_load
twix_to_nmrpipe
```

## Low level file IO

```@docs
load_rda
save_rda
load_twix
save_felix
save_nmrpipe
```

## High level signal processing

```@docs
extract_fids
simple_averaging
spectrum
```

## Low level signal processing

### Channel combination

```@docs
pca_channel_combiner
combine_channels
```

### Windows and windowing

```@docs
zeropad
apply_window
apply_window!
sinebell
```

### Water suppression

```@docs
hsvd
hsvd_water_suppression
```

### Phase correction

```@docs
adjust_phase
ernst
```

### Baseline correction

```@docs
baseline_als
```

## Plotting

```@docs
felix_colors
```

