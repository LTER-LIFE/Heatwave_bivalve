serial_ensemble <- function(run_indices_sub) {
  for (j in seq_along(run_indices_sub)) {
    i <- run_indices_sub[j]
    cat("Processing grid cell", j, "of", length(run_indices_sub), "\n")

    fHeight_raw <- as.numeric(out_WD_0.002_2020[i, 3:52562])
    fTwater_raw <- as.numeric(out_WT_0.002_2020[i, 3:52562])
    fTDeep_wad <- mean(fTwater_raw)

    fHeight_wad <- data.frame(time = forcing_times_1yr, depth = fHeight_raw)
    fTwater_wad <- data.frame(time = forcing_times_1yr, temperature = fTwater_raw)

    porfun <- function(x, por.SWI = 1, por.deep = 0.45,
                       porcoef = ext_coeff_list2020[j]) {
      por.deep + (por.SWI - por.deep) * exp(-x * porcoef)
    }
    cp_solid <- cp_solid_list2020[j]
    spinup_list <- list()
    delta_U <- Inf
    max_years <- 10
    year_count <- 0

    last_T_profile <- Temp.ini_2020_fixedDeepT

    while (delta_U > delta_U_threshold && year_count < max_years) {
      year_count <- year_count + 1
      cat("  Year", year_count, "\n")

      current_dtmax <- 600
      repeat {
        out <- tryCatch(
          {
            TempSED_run1D(
              parms = parms,
              times = times_1yr,
              T_ini = last_T_profile,
              z_max = z_max,
              dz_1 = dz_1,
              Grid = Grid,
              porosity = porfun,
              f_Waterheight = fHeight_wad,
              f_Watertemperature = fTwater_wad,
              f_Airtemperature = fTair.wad2020,
              f_Qrel = fHumidity.wad2020,
              f_Pressure = fPair.wad2020,
              f_Solarradiation = fRad.wad2020,
              f_Windspeed = fWind.wad2020,
              f_Cloudiness = fCloud.wad2020,
              f_Deeptemperature = fTDeep_wad,
              sedpos = NULL,
              dtmax = current_dtmax
            )
          },
          error = function(e) NULL
        )

        if (!is.null(out) && nrow(out) == 8760) break
        current_dtmax <- current_dtmax - 100
        if (current_dtmax < 100) {
          cat(j, "spinup failed: dtmax too small.\n")
          next
        }
      }

      spinup_list[[year_count]] <- out
      temp_mat <- as.matrix(out[, 2:101])
      dx <- Grid$dx
      porosity <- porfun(Grid$x.mid)
      rho_mix <- parms$density_solid * (1 - porosity) + parms$density_water * porosity
      cp_mix <- (cp_solid * parms$density_solid * (1 - porosity) +
        parms$cp_water * parms$density_water * porosity) / rho_mix

      if (year_count >= 2) {
        delta_T <- temp_mat[1, ] - last_T_profile
        delta_U <- sum(cp_mix * rho_mix * delta_T * dx) / 1e6
        cat(sprintf("    ΔU between year %d and %d = %.6f MJ/m²\n", year_count - 1, year_count, delta_U))
      }

      last_T_profile <- temp_mat[1, ]
    }

    if (delta_U > delta_U_threshold) {
      cat(j, "did not converge within 10 years. Skipping...\n")
      next
    }


    current_dtmax <- 600
    repeat {
      final_out <- tryCatch(
        {
          TempSED_run1D(
            parms = parms,
            times = times_1yr,
            T_ini = last_T_profile,
            z_max = z_max,
            dz_1 = dz_1,
            Grid = Grid,
            porosity = porfun,
            f_Waterheight = fHeight_wad,
            f_Watertemperature = fTwater_wad,
            f_Airtemperature = fTair.wad2020,
            f_Qrel = fHumidity.wad2020,
            f_Pressure = fPair.wad2020,
            f_Solarradiation = fRad.wad2020,
            f_Windspeed = fWind.wad2020,
            f_Cloudiness = fCloud.wad2020,
            f_Deeptemperature = fTDeep_wad,
            sedpos = NULL,
            dtmax = current_dtmax
          )
        },
        error = function(e) NULL
      )

      if (!is.null(final_out) && nrow(final_out) == 8760) break
      current_dtmax <- current_dtmax - 100
      if (current_dtmax < 100) {
        cat(j, "final run failed: dtmax too low.\n")
        break
      }
    }

    all_spinup <- do.call(rbind, spinup_list)
    final_data <- rbind(tail(all_spinup, 8760), final_out)

    saveRDS(final_data,
      file = sprintf(paste0(output_dir, "/output_cell_%04d.rds"), j)
    )
    cat(j, "final data: last 2 years saved.\n")
  }
}

multicore_ensemble <- function(j, ...) {
  i <- run_indices_sub[j]
  cat("Processing grid cell", j, "of", length(run_indices_sub), "\n")

  tryCatch({

    fHeight_raw <- as.numeric(out_WD_0.002_2020[i, 3:52562])
    fTwater_raw <- as.numeric(out_WT_0.002_2020[i, 3:52562])
    fTDeep_wad <- mean(fTwater_raw)

    fHeight_wad <- data.frame(time = forcing_times_1yr, depth = fHeight_raw)
    fTwater_wad <- data.frame(time = forcing_times_1yr, temperature = fTwater_raw)

    porfun <- function(x, por.SWI = 1, por.deep = 0.45,
                       porcoef = ext_coeff_list2020[j]) {
      por.deep + (por.SWI - por.deep) * exp(-x * porcoef)
    }

    cp_solid <- cp_solid_list2020[j]
    spinup_list <- list()
    delta_U <- Inf
    max_years <- 10
    year_count <- 0
    last_first_T_profile <- Temp.ini_2020_fixedDeepT
    last_T_profile <- Temp.ini_2020_fixedDeepT

    # Spin-up loop
    while (abs(delta_U) > delta_U_threshold && year_count < max_years) {
      year_count <- year_count + 1
      cat("  Year", year_count, "\n")
      current_dtmax <- 600

      repeat {
        out <- tryCatch({
          TempSED_run1D(
            parms = parms,
            times = times_1yr,
            T_ini = last_T_profile,
            z_max = z_max,
            dz_1 = dz_1,
            Grid = Grid,
            porosity = porfun,
            f_Waterheight = fHeight_wad,
            f_Watertemperature = fTwater_wad,
            f_Airtemperature = fTair.wad2020,
            f_Qrel = fHumidity.wad2020,
            f_Pressure = fPair.wad2020,
            f_Solarradiation = fRad.wad2020,
            f_Windspeed = fWind.wad2020,
            f_Cloudiness = fCloud.wad2020,
            f_Deeptemperature = fTDeep_wad,
            sedpos = NULL,
            dtmax = current_dtmax
          )
        }, error = function(e) NULL)

        if (!is.null(out) && nrow(out) == 8760) break
        current_dtmax <- current_dtmax - 100
        if (current_dtmax < 100) {
          cat(j, "spinup failed: dtmax too small.\n")
          stop("Spinup failed")
        }
      }

      spinup_list[[year_count]] <- out
      temp_mat <- as.matrix(out[, 2:101])
      dx <- Grid$dx
      porosity <- porfun(Grid$x.mid)
      rho_mix <- parms$density_solid * (1 - porosity) + parms$density_water * porosity
      cp_mix <- (cp_solid * parms$density_solid * (1 - porosity) +
                   parms$cp_water * parms$density_water * porosity) / rho_mix

      if (year_count >= 2) {
        current_first_T_profile <- temp_mat[1, ]
        delta_T <- current_first_T_profile - last_first_T_profile
        delta_U <- sum(cp_mix * rho_mix * delta_T * dx) / 1e6
        cat(sprintf("    ΔU between year %d and %d = %.6f MJ/m²\n", year_count - 1, year_count, delta_U))
      }

      last_first_T_profile <- temp_mat[1, ]
      last_T_profile <- temp_mat[8760, ]
    }

    if (abs(delta_U) > delta_U_threshold) {
      stop("Did not converge within 10 years")
    }

    all_spinup <- do.call(rbind, spinup_list)
    final_data <- tail(all_spinup, 8760 * 2)

    saveRDS(final_data,
            file = sprintf(paste0(output_dir, "/output_cell_%04d.rds"), j))
    cat(j, "final data: last 2 years saved.\n")

  }, error = function(e) {
    cat(j, "FAILED:", conditionMessage(e), "\n")
    failed_matrix <- matrix(NA, nrow = 8760 * 2, ncol = 118)
    failed_matrix[, 1] <- seq(3600, by = 3600, length.out = 8760 * 2)
    saveRDS(failed_matrix,
            file = sprintf(paste0(output_dir, "/output_cell_%04d.rds"), j))
  })
}
