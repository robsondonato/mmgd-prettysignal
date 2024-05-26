#' Example: Read Data from XLSX File
#'
#' This example demonstrates how to read a DataFrame from an XLSX file and use the solar_prettysignal function.
  library(openxlsx)

  #---------------------- Carregando arquivo de exemplo ------------------------
  name_file <- "example_data"
  ext <- ".xlsx"
  file_path <- system.file("demo", paste0(name_file, ext),
                           package = "solarprettysignal")
  #-----------------------------------------------------------------------------

  #------------ Carregue o seu arquivo conforme Template definido --------------
  # O arquivo .xlsx deve conter as colunas Data, Year, Month, Day e Hour.
  # Passe para a variável file_path o caminho do seu arquivo, conforme indicado:

  #name_file <- "example_data"
  #ext <- ".xlsx"
  # file_path <- paste0("diretorio_do_seu_arquivo", paste0(name_file, ext))
  #-----------------------------------------------------------------------------

  #-------------------------- Ler o arquivo XLSX -------------------------------
  dados_to_be_treated <- read.xlsx(file_path, sheet = 1)
  #-----------------------------------------------------------------------------

  #---------------------------- Processa Dados ---------------------------------
  result <- solar_prettysignal(dados_to_be_treated, TRUE)
  #-----------------------------------------------------------------------------

  #-------- Salva arquivo de Saida no Diretorio do arquivo de entrada ----------
  name_file_results <- paste0(dir, name_file, "_filtered", ext)
  write.xlsx(result, name_file_results, sheetName = "results", rowNames = FALSE)
  #-----------------------------------------------------------------------------

  #----------------- Plotar os dados originais e filtrados ---------------------
  plot(result$Time,
       result$Original_data,
       type = 'l',
       col = 'blue', lty = 1, lwd = 2,
       ylab = 'Value', xlab = 'Time', main = 'Original and Filtered Data')
  lines(result$Time, result$Filtered_data, col = 'black', lty = 1, lwd = 2)
  legend('topright',
         legend = c('Original Data', 'Solar Pretty Signal Data'),
         col = c('blue', 'black'), lty = 1:1, lwd = c(1, 2), cex = 0.7)
  #-----------------------------------------------------------------------------
