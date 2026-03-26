#tesla data analyss
library(tidyverse)
library(lubridate)
library(tidyverse)
library(lubridate)



tesla <- read.csv("C:/Users/mickey/Desktop/su work/1.2/timeseries/Garch_Assignment/TSLA1.csv")
head(tesla)
tail(tesla)

str(tesla$Date)

tesla$Date <- as.Date(tesla$Date)
str(tesla$Date)


tesla <- tesla %>%
  arrange(Date) %>%
  mutate(
    log_return = 100 * (log(Adj.Close) - log(lag(Adj.Close)))
  ) %>%
  drop_na()

head(tesla$log_return)
summary(tesla$log_return)

plot(tesla$Date, tesla$log_return, type = "l",
     main = "Tesla Daily Log Returns",
     xlab = "Date",
     ylab = "Log Returns (%)")



## confirm conditional heteroskedasticity
library(FinTS)
ArchTest(tesla$log_return, lags = 12)

##The ARCH LM test strongly rejects the null hypothesis of homoskedasticity (Chi-squared = 173.2, df = 12, p < 0.0001), indicating the presence of time-varying volatility in Tesla’s daily returns. This confirms that a GARCH model is appropriate for capturing the conditional variance dynamics.


plot(tesla$log_return^2, type="l")  # shows squared returns




## Deploy a GARCH model
library(rugarch)

spec_garch <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1,1)),
  mean.model     = list(armaOrder = c(0,0), include.mean = TRUE),
  distribution.model = "std"  # Student-t for fat tails
)

fit_garch <- ugarchfit(
  spec = spec_garch,
  data = tesla$log_return
)

show(fit_garch)


## visualization
library(xts)

# Convert returns to xts (use the correct data name: tesla)
tesla_xts <- xts(tesla$log_return, order.by = tesla$Date)

# Extract conditional volatility from GARCH
volatility <- sigma(fit_garch)

# Plot
plot(tesla$Date, volatility, type = "l", col = "blue",
     main = "Estimated Conditional Volatility (GARCH 1,1)",
     xlab = "Date", ylab = "Volatility (%)")



## Model diagnostics
residuals <- residuals(fit_garch, standardize = TRUE)

# Ljung-Box test on squared residuals
Box.test(residuals^2, lag = 20, type = "Ljung-Box")

acf(residuals, main = "ACF of Standardized Residuals")

ArchTest(residuals, lags = 12)

hist(residuals, breaks = 50, main="Histogram of Standardized Residuals", xlab="Residuals")

qqnorm(residuals); qqline(residuals, col="red")

## visualization
par(mfrow=c(2,1))
acf(residuals, main="ACF of Standardized Residuals")
acf(residuals^2, main="ACF of Squared Standardized Residuals")
par(mfrow=c(1,1))

# Forecast 10 days ahead using your fitted GARCH model
forecast <- ugarchforecast(fit_garch, n.ahead = 10)

# Extract forecasted conditional volatility
vol_forecast <- sigma(forecast)

# Create sequence of dates starting from last observation
last_date <- as.Date("2021-10-18")  # your actual last date
forecast_dates <- seq(last_date + 1, by = "days", length.out = 10)

# Combine volatility with forecast dates
vol_forecast_xts <- xts(vol_forecast, order.by = forecast_dates)

# View the forecast table
vol_forecast_xts













