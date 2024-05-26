#' Example: Create DataFrame Manually
#'
#' This example demonstrates how to create a DataFrame manually and use the solar_prettysignal function.

  # Dados do sinal para 4 dias (96 valores)
  signal <- c(
    0, 0, 0, 0, 0, 0.299363344, 52.87804786, 211.0239098, 286.8509549, 331.8250828, 376.7992108, 421.7733387,
    392.9003759, 364.0274131, 335.1544502, 196.3029159, 166.3754798, 28.66203888, 0.328820828, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 31.28610471, 123.2366787, 208.9158892, 315.209041, 323.2168082, 348.466492, 392.6733798,
    356.840256, 321.0071321, 285.3801118, 165.0771309, 35.96607852, 0.355951728, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1.272294211, 25.52285671, 97.61949497, 200.1408234, 320.3221024, 323.5279288, 337.0632899, 366.0005609,
    323.167164, 236.9225964, 97.02581678, 96.80369218, 39.72400771, 0.473878103, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0.094775621, 40.35322469, 132.8195423, 180.3149746, 264.5757103, 362.9652116, 418.2399122, 347.6725199,
    344.7272337, 326.3798059, 304.2112904, 229.89446, 50.62983859, 0.234045207, 0, 0, 0, 0, 0
  )

  # Criando o DataFrame com 4 dias de dados medidos (96 valores)
  dados_to_be_treated <- data.frame(
    Data = signal,
    Year = rep(2024, length(signal)),
    Month = rep(1, length(signal)),
    Day = rep(1:4, each = 24),
    Hour = rep(1:24, times = 4)
  )

  result <- solar_prettysignal(dados_to_be_treated, TRUE)

  # Plotar os dados originais
  plot(result$Time, result$Original_data, type = 'l', col = 'blue', lty = 1, lwd = 2, ylab = 'Value', xlab = 'Time', main = 'Original and Filtered Data')
  lines(result$Time, result$Filtered_data, col = 'black', lty = 1, lwd = 2)
  legend('topright', legend = c('Original Data', 'Solar Pretty Signal Data'), col = c('blue', 'black'), lty = 1:1, lwd = c(1, 2), cex = 0.7)
