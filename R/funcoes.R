#' List available example scripts
#'
#' This function lists the example scripts available in the package.
#' @export
list_solar_prettysignal_examples <- function() {
  examples_path <- system.file("examples", package = "solarprettysignal")
  example_files <- list.files(examples_path, pattern = "\\.R$", full.names = TRUE)
  example_files <- basename(example_files)
  example_files
}


#' Run an example script
#'
#' This function runs a specified example script.
#' @param example_name The name of the example script to run (without extension).
#' @export
run_solar_prettysignal_example <- function(example_name) {
  examples_path <- system.file("examples", package = "solarprettysignal")
  example_file <- file.path(examples_path, paste0(example_name))

  if (!file.exists(example_file)) {
    stop("The specified example does not exist.")
  }

  temp_dir <- tempdir()
  file.copy(example_file, temp_dir, overwrite = TRUE)
  example_path <- file.path(temp_dir, paste0(example_name))

  message("Opening example: ", example_name)
  file.edit(example_path)
}

# Função para encontrar picos e vales
encontrar_picos_vales <- function(signal) {
  picos <- c()
  vales <- c()
  for (i in 2:(length(signal)-1)) {
    if (signal[i] > signal[i-1] && signal[i] > signal[i+1]) {
      picos <- c(picos, i)
    } else if (signal[i] < signal[i-1] && signal[i] < signal[i+1] && signal[i] != 0) {
      vales <- c(vales, i)
    }
  }
  return(list(picos = picos, vales = vales))
}

# Função para calcular o ângulo entre três pontos
calcular_angulo <- function(a, b, c) {
  ab <- c(b[1] - a[1], b[2] - a[2])
  bc <- c(c[1] - b[1], c[2] - b[2])

  produto_escalar <- sum(ab * bc)
  norma_ab <- sqrt(sum(ab^2))
  norma_bc <- sqrt(sum(bc^2))

  cos_theta <- produto_escalar / (norma_ab * norma_bc)
  angulo <- acos(cos_theta) * (180 / pi)

  return(angulo)
}

# Função para ajustar o pico máximo
ajustar_pico_maximo <- function(signal) {
  pico_maximo <- which.max(signal)

  if (pico_maximo > 1 && pico_maximo < length(signal)) {
    esquerda <- c(pico_maximo - 1, signal[pico_maximo - 1])
    pico_valor <- c(pico_maximo, signal[pico_maximo])
    direita <- c(pico_maximo + 1, signal[pico_maximo + 1])

    angulo <- calcular_angulo(esquerda, pico_valor, direita)

    if (angulo < 50) {
      signal[pico_maximo] <- min(signal[pico_maximo - 1], signal[pico_maximo + 1]) +
        (abs(signal[pico_maximo - 1] - signal[pico_maximo + 1]) / sqrt(3))
    }
  }

  return(signal)
}

# Função para corrigir os dentes
corrigir_dentes <- function(signal) {
  pv <- encontrar_picos_vales(signal)
  picos <- pv$picos
  vales <- pv$vales
  corrigido_signal <- ajustar_pico_maximo(signal)

  for (vale in vales) {
    picos_anteriores <- picos[picos < vale]
    picos_posteriores <- picos[picos > vale]

    if (length(picos_anteriores) > 0 && length(picos_posteriores) > 0) {
      pos_pico_anterior <- max(picos_anteriores)
      pos_pico_posterior <- min(picos_posteriores)

      x_vals <- c(pos_pico_anterior, pos_pico_posterior)
      y_vals <- c(corrigido_signal[pos_pico_anterior], corrigido_signal[pos_pico_posterior])

      coef <- lm(y_vals ~ x_vals)$coefficients

      for (i in (pos_pico_anterior + 1):(pos_pico_posterior - 1)) {
        corrigido_signal[i] <- coef[1] + coef[2] * i
      }
    }
  }

  return(corrigido_signal)
}

# Função principal
#' Solar Pretty Signal
#'
#' This function receives measured data of photovoltaic generation or solar irradiation, applies filtering and processing and returns the filtered data.
#' @param dados_to_be_treated DataFrame with the values to be processed. This DataFrame must have the columns *Data*, *Year*, *Month*, *Day*, and *Hour*. The *Data* column should contain the values to be processed, which can be measured data of photovoltaic generation or solar irradiation. 24 values per day must be provided.
#' @param midnight_is_first_hour Boolean indicating whether *midnight* is the first hour of the day.
#' @return Data frame with the *original data* and the *filtered data*.
#' @export
solar_prettysignal <- function(dados_to_be_treated, midnight_is_first_hour) {

  # Transformar a coluna Data em numeric
  dados_to_be_treated <- dados_to_be_treated %>%
    mutate(Data = as.numeric(Data))

  # Ordenar os dados por Year, Month, Day, Hour
  dados_to_be_treated <- dados_to_be_treated %>%
    arrange(Year, Month, Day, Hour)

  # Verificação de mês dentro do domínio de 1 a 12
  if (any(dados_to_be_treated$Month < 1 | dados_to_be_treated$Month > 12)) {
    stop("Erro: Os meses devem estar no domínio de 1 a 12.Revise seus dados, há um ou mais número de meses fora desse intervalo.")
  }

  # Verificação de dias dentro do domínio de 1 a 31
  if (any(dados_to_be_treated$Day < 1 | dados_to_be_treated$Day > 31)) {
    stop("Erro: Os dias devem estar no domínio de 1 a 31. Revise seus dados, há um ou mais número de dias fora desse intervalo.")
  }

  # Verificação de horas dentro do domínio de 0 a 23
  if (any(dados_to_be_treated$Hour < 1 | dados_to_be_treated$Hour > 24)) {
    stop("Erro: As horas devem estar do domínio de 1 a 24. Revise seus dados, há uma ou mais horários fora desse intervalo.")
  }

  # Verificação de dias em fevereiro
  invalid_february_days <- dados_to_be_treated %>%
    filter(Month == 2 & ((Day > 29) | (Day == 29 & !leap_year(Year)))) %>%
    select(Year, Month, Day)

  if (nrow(invalid_february_days) > 0) {
    stop("Erro: Existem dias inválidos no mês de fevereiro.")
  }

  # Função para tratar cada dia individualmente
  tratar_dia <- function(dado_de_um_dia, year, month, day) {
    # Verificação de hora repetida dentro de um dia
    if (any(duplicated(dado_de_um_dia$Hour))) {
      stop(paste("Erro: Existem horas repetidas no dia", day, "do mês", month, "do ano", year, "."))
    }

    if (nrow(dado_de_um_dia) != 24) {
      stop(paste("Erro: O dia", day, "do mês", month, "do ano", year, "não possui 24 valores."))
    }

    corrigido_signal <- corrigir_dentes(dado_de_um_dia$Data)
    dados_de_um_dia_mmgd <- corrigido_signal

    # Identificando intervalos de Zeros
    rle_zeros <- rle(dados_de_um_dia_mmgd == 0)
    starts_ends <- data.frame(
      Start = cumsum(rle_zeros$lengths)[rle_zeros$values] - rle_zeros$lengths[rle_zeros$values] + 1,
      End = cumsum(rle_zeros$lengths)[rle_zeros$values],
      Length = rle_zeros$lengths[rle_zeros$values]
    )

    # Aplicando a Transformada de Fourier
    fft_dados_de_um_dia_mmgd <- fft(dados_de_um_dia_mmgd)
    n_dia <- length(dados_de_um_dia_mmgd)
    frequencias_dia <- seq(0, n_dia-1) / n_dia * (1/1)  # Ciclos por hora
    limite_frequencia_dia <- 0.2

    # Filtrando as altas frequências
    fft_dados_de_um_dia_mmgd[4] <- 0
    fft_dados_de_um_dia_mmgd[length(fft_dados_de_um_dia_mmgd)-2] <- 0
    fft_dados_de_um_dia_mmgd[frequencias_dia > limite_frequencia_dia & frequencias_dia < 1 - limite_frequencia_dia] <- 0

    # Aplicando a Transformada de Fourier Inversa
    dados_de_um_dia_mmgd_filtrado <- Re(fft(fft_dados_de_um_dia_mmgd, inverse = TRUE) / n_dia)
    dados_de_um_dia_mmgd_filtrado <- dados_de_um_dia_mmgd_filtrado - min(dados_de_um_dia_mmgd_filtrado)

    # Filtrando e calculando o valor médio dos intervalos de zero no vetor filtrado
    valores_medios <- sapply(1:nrow(starts_ends), function(i) {
      mean(dados_de_um_dia_mmgd_filtrado[starts_ends$Start[i]:starts_ends$End[i]])
    })

    maior_valor_medio <- max(valores_medios)
    dados_de_um_dia_mmgd_filtrado <- dados_de_um_dia_mmgd_filtrado - maior_valor_medio
    for(i in 1:nrow(starts_ends)) {
      dados_de_um_dia_mmgd_filtrado[starts_ends$Start[i]:starts_ends$End[i]] <- 0
    }
    dados_de_um_dia_mmgd_filtrado[dados_de_um_dia_mmgd_filtrado < 0] <- 0

    # Preparando o vetor de horas para o dia específico
    if(midnight_is_first_hour){
      t_dia <- seq(from = as.POSIXct(paste(year,"-", month, "-", day, " 00:00:00", sep="")), by = "hour", length.out = length(dados_de_um_dia_mmgd))
    } else {
      t_dia <- seq(from = as.POSIXct(paste(year,"-", month, "-", day, " 01:00:00", sep="")), by = "hour", length.out = length(dados_de_um_dia_mmgd))
    }

    return(data.frame(
      Time = t_dia,
      Original_data = dados_de_um_dia_mmgd,
      Filtered_data = dados_de_um_dia_mmgd_filtrado
    ))
  }

  # Aplicando a função para cada dia
  resultado <- dados_to_be_treated %>%
    group_by(Year, Month, Day) %>%
    group_modify(~ tratar_dia(.x, .y$Year, .y$Month, .y$Day)) %>%
    ungroup()

  resultado$Filtered_data <- corrigir_dentes(resultado$Filtered_data)

  return(resultado)
}

