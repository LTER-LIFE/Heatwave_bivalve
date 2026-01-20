#####

# Configuration (do not containerize this cell)
param_minio_endpoint = "scruffy.lab.uvalight.net:9000"
param_minio_user_prefix = "zhanqing2016@gmail.com"  # Your personal folder in the naa-vre-user-data bucket in MinIO
secret_minio_access_key = "sFmE1jsm5hjJBBGh5RBL"
secret_minio_secret_key = "pczCG6FRpXQEtad7lAvXv00iCYFd5Dpa1g8GOWzR"

# Access MinIO files
install.packages("aws.s3")
library("aws.s3")
Sys.setenv("AWS_S3_ENDPOINT" = param_minio_endpoint,
           "AWS_DEFAULT_REGION" = param_minio_region,
           "AWS_ACCESS_KEY_ID" = secret_minio_access_key,
           "AWS_SECRET_ACCESS_KEY" = secret_minio_secret_key)

# List existing buckets: get a list of all available buckets
bucketlist()

# List files in bucket: get a list of files in a given bucket. For bucket `naa-vre-user-data`, only list files in your personal folder
get_bucket_df(bucket="naa-vre-user-data", prefix=paste0(param_minio_user_prefix, "/"))

# Upload file to bucket: uploads `myfile_local.csv` to your personal folder on MinIO as `myfile.csv`
put_object(bucket="naa-vre-user-data", file="myfile_local.csv", object=paste0(param_minio_user_prefix, "/myfile.csv"))

# Download file from bucket: download `myfile.csv` from your personal folder on MinIO and save it locally as `myfile_downloaded.csv`
save_object(bucket="naa-vre-user-data", object=paste0(param_minio_user_prefix, "/myfile.csv"), file="myfile_downloaded.csv")

########

library(devtools)
load_all("~/ricky_proj/TempSED")
require(ReacTran)
require(pracma)
library(parallel)

# === Load Data ===
load("TempSED/data/obs2020.rda")
fWind.wad2020      <-   obs2020[,c("Second", "windSpeed")]
fRad.wad2020       <-   obs2020[,c("Second", "radiation")]
fTair.wad2020      <-   obs2020[,c("Second", "airTemperature")]
fPair.wad2020      <-   obs2020[,c("Second", "airPressure")]
fHumidity.wad2020  <-   obs2020[,c("Second", "airHumidity")]
fCloud.wad2020     <-   obs2020[,c("Second", "cloudCover")]

load("TempSED/data/out_WD_0.002_2020.rda")
load("TempSED/data/out_WT_0.002_2020.rda")

load("TempSED/data/sed_pars2020.rda")
load("TempSED/data/run_indices2020.rda")
load("TempSED/data/Temp.ini_2020_fixedDeepT.rda")


source("run_ensemble_2020.R")

# === Universal Parameters ===
z_max <- 10
dz_1     <- 1e-4
Grid = setup.grid.1D(N = 100, dx.1 = dz_1, L = z_max)

parms <- list(
  em_air = 0.8,
  em_sediment = 0.95,
  stanton = 0.001,
  dalton = 0.0014,
  density_water = 1024,
  density_solid = 2500,
  cp_water = 3994,
  tc_water = 0.6,
  tc_solid = 7,
  albedo_water = 0.05,
  kd_water = 1,
  kd_sediment = 1000
)

# === Model Run ===
output_dir <- "./output_dir/multicore/output_list_OS_2020_fixedDeepT_2yr"
#dir.create("../data/output_list_OS_2020_fixedDeepT_2yr", showWarnings = FALSE)

if(!dir.exists(output_dir)) dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)


seconds_per_year <- 365 * 24 * 3600
times_1yr <- seq(from = 3600, by = 3600, length.out = 8760)
forcing_times_1yr <- seq(from = 3600, by = 600, length.out = 52560)

delta_U_threshold <- 0.001

run_indices_sub = run_indices2020[1:3114]



cores <- as.numeric(Sys.getenv("SLURM_CPUS_PER_TASK"))
out <- mclapply(seq_along(run_indices_sub), multicore_ensemble, mc.cores = cores)

