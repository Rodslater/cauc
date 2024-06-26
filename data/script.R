library(dplyr)
library(tidyr)
library(stringr)
library(rvest)
library(readxl)
library(data.table)

################# DOWNLOAD ################# 
site <- read_html("https://www.tesourotransparente.gov.br/ckan/dataset/cauc/resource/07af297a-5e59-494a-a88a-55ddfd2f4b01")

link <- site |> html_nodes(xpath="//a[contains(text(), '.csv')]") |> html_attr("href")
destinos <- c("CAUC.csv")

Map(function(u, d) download.file(u, d, mode="wb"), link, destinos)
################# DOWNLOAD ################# 


cauc <- fread("CAUC.csv", skip = 3, header = TRUE, sep = ";", encoding = "Latin-1") 
#file.remove("CAUC.csv")

cauc <- cauc |> 
  filter(UF == "SE") |> 
  mutate(across(where(is.character), ~ gsub("/2", "/202", .x))) |> 
  rename(cod_ibge = `Código IBGE`)


municipios <- read.csv2('data/municipios.csv')

cauc <- municipios |> 
  left_join(cauc, by ='cod_ibge') |> 
  select(-c(Município, UF, `Nome do Ente Federado`, `Código SIAFI`, Região, População, Fonte))


codigos_cauc <- read_excel('data/codigos CAUC.xlsx')

cauc <- cauc |> 
  rename_with(~ codigos_cauc$Exigência[match(., codigos_cauc$Código)], matches(codigos_cauc$Código))  |> 
  pivot_longer(cols = -cod_ibge, 
             names_to = "Exigência", 
             values_to = "Valor")

cauc <- cauc |> 
  filter(Valor != 'Desabilitado') |> 
  mutate(Cumprimento = ifelse(Valor == '!', 'A comprovar', 'Comprovado'),
         Valor = str_replace(Valor, '!', '-')) |> 
  rename(`Validade da informação` = Valor) |> 
  relocate(`Validade da informação`, .after = last_col())


saveRDS(cauc, 'data/cauc.rds')


atualizacao_cauc <- read.csv("CAUC.csv", header = FALSE) |> 
  slice(1) |> 
  rename(atualizacao_cauc = V1) |> 
  mutate(atualizacao_cauc = str_replace(atualizacao_cauc, "Data da Pesquisa: ", ""))

saveRDS(atualizacao_cauc, 'data/atualizacao_cauc.rds')
