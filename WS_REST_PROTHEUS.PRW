#include "protheus.ch"
#include "restful.ch"
#include "tbiconn.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"

#define enter chr(13) + chr(10)

//m9i8c7r6

User Function EREST_02()
Return

WSRESTFUL INT_PIMS_041M DESCRIPTION "Serviço REST para requisicoes eletronicas"

//COLOCAR CAMPOS OBRIGATORIOS ABAIXO
WSDATA cRet		AS STRING

WSMETHOD GET  DESCRIPTION "Retorna o produto informado na URL" WSSYNTAX "/REQUISICOES ELETRONICAS || /REQUISICOES ELETRONICAS/{}"
WSMETHOD POST DESCRIPTION "POST / INCLUSAO REQUISICOES ELETRONICAS" WSSYNTAX ""

END WSRESTFUL

WSMETHOD GET WSSERVICE INT_PIMS_041M

Local aArea      := GetArea()
Local cNextAlias := GetNextAlias()
//Local oCliente   := CLIENTES():New() // –> Objeto da classe cliente
//Local oResponse  := FULL_CLIENTES():New() // –> Objeto que será serializado
Local cJSON      := ::getContent()
Local lRet       := .T.

oParseJSON	:= nil

::setContentType("application/json")
FWJsonDeserialize(cJson, @oParseJSON)

/*
BeginSQL Alias cNextAlias
SELECT CTT_FILIAL, CTT_CUSTO, CTT_CLASSE, CTT_DESC01
FROM %table:CTT% CTT
WHERE CTT.%notdel%
EndSQL

(cNextAlias)->( DbGoTop() )
If (cNextAlias)->( !Eof() )
   While (cNextAlias)->( !Eof() )
      ::setResponse('{') 
      ::setResponse( '"Filial ": "' + AllTrim((cNextAlias)->CTT_FILIAL) + '",')
      ::setResponse( '"Codigo ": "' + AllTrim((cNextAlias)->CTT_CUSTO) + '",')
      ::setResponse( '"Descricao ": "' + AllTrim((cNextAlias)->CTT_DESC01) + '",')
      ::setResponse( '"Classe ": "' + AllTrim((cNextAlias)->CTT_CLASSE) + '"')
      ::setResponse('}')
      (cNextAlias)->( DbSkip() )
   EndDo
   //cJSON := FWJsonSerialize(oResponse, .T., .T.,,.F.)
   //::SetResponse(cJSON)
   setRestFault(002,"Não encontrado nenhum Centro de Custo na Base")
Else
   SetRestFault(400, "CTT Empty")
   lRet := .F.
EndIf
*/

      ::setResponse('{') 
      ::setResponse( '"TESTE": "TESTE OK" ')
      ::setResponse('}')

RestArea(aArea)

Return(lRet)

WSMETHOD POST WSRECEIVE RECEIVE WSSERVICE INT_PIMS_041M

Local aJSon         := {}
Local aLog		    := {}
Local oParseJSON    := nil
Local cJson         := ::getContent()
Local cUniEmp		:= 	""
Local cFilEmp		:= 	""
Local lInclui       := .T.
Local _lTdOk        := .T.
Local _cRetInco     := ""
Local _cRetJson     := ""

Local aCab          := {}
Local aItens        := {}
Local nSaveSx8      := 0
Local cNumero       := ''

Local nOpcx         := 3

Private lMsErroAuto := .f.
Private lMsErroHelp := .T.

::setContentType("application/json")
FWJsonDeserialize(cJson, @oParseJSON)

If ValType(oParseJSON) == "A" //json com mais de 1 linha
   cUniEmp := oParseJSON[1]:COL004C
   cFilEmp := oParseJSON[1]:COL005C
Else
   cUniEmp := oParseJSON:COL004C
   cFilEmp := oParseJSON:COL005C
EndIf

RpcSetEnv(cUniEmp,cFilEmp,"","","EST")
cEmpAnt := cUniEmp
cFilAnt := cFilEmp

BEGIN TRANSACTION  


If ValType(oParseJSON) == "A" //json com mais de 1 linha
   _nIJson   := 1
   _nTamJson := Len(oParseJSON)
   While _nIJson <= _nTamJson
      aJSon := {}
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL001N,"N")) //Identificador exclusivo (PK) - Número sequencial
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL002C,"C")) //Módulo origem - PIMS-MI = Manut. Industrial; MANCRO = Manut. Automotiva
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL003C,"C")) //Empresa (MI) ou Instância (MANFRO) do PIMS
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL004C,"C")) //Código da empresa/organização no ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL005C,"C")) //Código da filial/estabelecimento no ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL006N,"N")) //Identificador no MI (id_ospecprev)
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL007N,"N")) //Número do Boletim (MANFRO) ou OS (MI)
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL008N,"N")) //Número da sequência
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL009C,"C")) //Código do item no ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL010C,"C")) //Descrição do item
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL011C,"C")) //Detalhamento do Material/Serviço
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL012N,"N")) //Quantidade solicitada
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL013C,"C")) //Unidade de medida
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL014D,"C")) //Data da solicitação
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL015C,"C")) //Depósito da requisição e baixa do item quando for requisição interna
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL016N,"N")) //Custo unitário previsto para o item - Default 0
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL017C,"C")) //Código do centro de custo do ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL018C,"C")) //Tipo do movimento - Sempre "S"
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL019C,"C")) //Tipo do documento a ser gerado no ERP - "R" = Requisição interna; "S" = Solic. Compra Material; "X" = Solic. Compra Serviço
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL020C,"C")) //Código Investimento
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL021C,"C")) //Tipo de aplicação - "M" = Manutenção; "I" = Investimento.
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL022C,"C")) //Usuário solicitante
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL023C,"C")) //Equipe solicitante
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL024D,"C")) //Data prevista de utilização
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL025C,"C")) //Informa se haverá inspeção interna - "S" = Sim; "N" = Não
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL026C,"C")) //Informa se haverá inspeção externa - "S" = Sim; "N" = Não
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL027C,"C")) //Detalhamento da inspeção
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL028C,"C")) //Comentário sobre o item em questão
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL029C,"C")) //Comentário ao comprador
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL030C,"C")) //Código do crachá do solicitante
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL031C,"C")) //Informa se efetua a baixa automaticamente - Default "N"
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL032C,"C")) //Situação do lançamento - Inserido pelo PIMS e atualizado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL033C,"C")) //Número do documento no ERP - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL034C,"C")) //Item do documento no ERP - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL035N,"N")) //Número da solicitação - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL036N,"N")) //Número do pedido - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL037C,"C")) //Nome do comprador - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL038D,"C")) //Previsão de entrega - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL039D,"C")) //Data e hora do envio do PIMS para a tabela intermediária - Sysdate
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL040D,"C")) //Data e hora da integração no ERP - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL041C,"C")) //Mensagem de retorno de inconsistência - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL042C,"C"))

      _cRetInco := ""

      SB1->(DbSetOrder(1))
      If !SB1->(DbSeek(xFilial("SB1")+Padr(aJSon[09],TamSx3("B1_COD")[1])))
         _lTdOk := .F.
         _cRetInco := "PRODUTO (SB1) NAO LOCALIZADO"
      Else
         NNR->(DbSetOrder(1))
         If !NNR->(DbSeek(xFilial("NNR")+Padr(aJSon[15],TamSx3("NNR_CODIGO")[1])))
            _lTdOk := .F.
            _cRetInco := "ALMOXARIFADO (NNR) NAO LOCALIZADO"
         Else
            SB2->(DbSetOrder(1))
            If !SB2->(DbSeek(xFilial("SB2")+Padr(aJSon[09],TamSx3("B2_COD")[1])+Padr(aJSon[15],TamSx3("B2_LOCAL")[1])))
               _lTdOk := .F.
               _cRetInco := "PRODUTO + ALMOXARIFADO (SB2) NAO LOCALIZADO"
            Else
               CTT->(DbSetOrder(1))
               If !CTT->(DbSeek(xFilial("CTT")+Padr(aJSon[17],TamSx3("CTT_CUSTO")[1])))
                  _lTdOk    := .F.
                  _cRetInco := "CENTRO DE CUSTO (CTT) NAO LOCALIZADO"
               EndIf
            EndIf
         EndIf
      EndIf
      
      If Empty(aCab) .and. _lTdOk
         nSaveSx8 := GetSx8Len()
         cNumero  := GetSx8Num('SCP','CP_NUM')

         DbSelectArea('SB1')
         SB1->(DbSetOrder(1))

         DbSelectArea('SCP')
         SCP->(DbSetOrder(1))

         If nOpcx == 3
            While SCP->( DbSeek(xFilial('SCP')+cNumero))
               ConfirmSx8()
               cNumero := GetSx8Num('SCP','CP_NUM')
            EndDo
         EndIf

         Aadd(aCab,{"CP_NUM"     ,cNumero   , Nil })
         Aadd(aCab,{"CP_EMISSAO" ,dDataBase , Nil })
         Aadd(aCab,{"CP_SOLICIT" ,aJSon[22] , Nil })

      EndIf

      If _nIJson == 1
         ::cRet := "Processo em Lote "
         _cRetJson := _cRetJson + '[' + enter
      EndIf
      If !_lTdOk
         conOut(enter + oemToAnsi("Erro na busca de registro na inclusao! ") + enter)

         _cRetJson := _cRetJson + '{' + enter
         _cRetJson := _cRetJson + '"col001n": '+AllTrim(Str(aJSon[01]))+',' + enter
         _cRetJson := _cRetJson + '"col002c": "'+aJSon[02]+'",' + enter
         _cRetJson := _cRetJson + '"col003c": "'+aJSon[03]+'",' + enter
         _cRetJson := _cRetJson + '"col004c": "'+aJSon[04]+'",' + enter
         _cRetJson := _cRetJson + '"col005c": "'+aJSon[05]+'",' + enter
         _cRetJson := _cRetJson + '"col006n": '+Str(aJSon[06])+',' + enter
         _cRetJson := _cRetJson + '"col007n": '+Str(aJSon[07])+',' + enter
         _cRetJson := _cRetJson + '"col008n": '+Str(aJSon[08])+',' + enter
         _cRetJson := _cRetJson + '"col009c": "'+aJSon[09]+'",' + enter
         _cRetJson := _cRetJson + '"col010c": "'+aJSon[10]+'",' + enter
         _cRetJson := _cRetJson + '"col011c": "'+aJSon[11]+'",' + enter
         _cRetJson := _cRetJson + '"col012n": '+Str(aJSon[12])+',' + enter
         _cRetJson := _cRetJson + '"col013c": "'+aJSon[13]+'",' + enter
         _cRetJson := _cRetJson + '"col014d": "'+aJSon[14]+'",' + enter
         _cRetJson := _cRetJson + '"col015c": "'+aJSon[15]+'",' + enter
         _cRetJson := _cRetJson + '"col016n": '+Str(aJSon[16])+',' + enter
         _cRetJson := _cRetJson + '"col017c": "'+aJSon[17]+'",' + enter
         _cRetJson := _cRetJson + '"col018c": "'+aJSon[18]+'",' + enter
         _cRetJson := _cRetJson + '"col019c": "'+aJSon[19]+'",' + enter
         _cRetJson := _cRetJson + '"col020c": "'+aJSon[20]+'",' + enter
         _cRetJson := _cRetJson + '"col021c": "'+aJSon[21]+'",' + enter
         _cRetJson := _cRetJson + '"col022c": "'+aJSon[22]+'",' + enter
         _cRetJson := _cRetJson + '"col023c": "'+aJSon[23]+'",' + enter
         _cRetJson := _cRetJson + '"col024d": "'+aJSon[24]+'",' + enter
         _cRetJson := _cRetJson + '"col025c": "'+aJSon[25]+'",' + enter
         _cRetJson := _cRetJson + '"col026c": "'+aJSon[26]+'",' + enter
         _cRetJson := _cRetJson + '"col027c": "'+aJSon[27]+'",' + enter
         _cRetJson := _cRetJson + '"col028c": "'+aJSon[28]+'",' + enter
         _cRetJson := _cRetJson + '"col029c": "'+aJSon[29]+'",' + enter
         _cRetJson := _cRetJson + '"col030c": "'+aJSon[30]+'",' + enter
         _cRetJson := _cRetJson + '"col031c": "'+aJSon[31]+'",' + enter
         _cRetJson := _cRetJson + '"col032c": "ER",' + enter
         _cRetJson := _cRetJson + '"col033c": "",' + enter
         _cRetJson := _cRetJson + '"col034c": "",' + enter
         _cRetJson := _cRetJson + '"col035n": '+Str(aJSon[35])+',' + enter
         _cRetJson := _cRetJson + '"col036n": '+Str(aJSon[36])+',' + enter
         _cRetJson := _cRetJson + '"col037c": "'+aJSon[37]+'",' + enter
         _cRetJson := _cRetJson + '"col038d": "'+aJSon[38]+'",' + enter
         _cRetJson := _cRetJson + '"col039d": "'+aJSon[39]+'",' + enter
         _cRetJson := _cRetJson + '"col040d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter
         _cRetJson := _cRetJson + '"col041c": "'+_cRetInco+'", ' + enter
         _cRetJson := _cRetJson + '"col042c": "NI",' + enter
         _cRetJson := _cRetJson + '"col043d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'"' + enter

         If _nIJson == _nTamJson
            _cRetJson := _cRetJson + '}' + enter
         Else
            _cRetJson := _cRetJson + '},' + enter
         EndIf
      Else
         SCP->(DbOrderNickName("XIDPIMSPRO"))
         If SCP->(DbSeek(xFilial("SCP")+Padr(AllTrim(Str(aJSon[01])),TamSx3("CP_XIDPIMS")[1])+Padr(aJSon[09],TamSx3("CP_PRODUTO")[1])))
            cNumero := SCP->CP_NUM
            conOut(enter + oemToAnsi("Registro ja existe! Codigo: ") + cNumero + enter)

            _cRetJson := _cRetJson + '{' + enter
            _cRetJson := _cRetJson + '"col001n": '+AllTrim(Str(aJSon[01]))+',' + enter
            _cRetJson := _cRetJson + '"col002c": "'+aJSon[02]+'",' + enter
            _cRetJson := _cRetJson + '"col003c": "'+aJSon[03]+'",' + enter
            _cRetJson := _cRetJson + '"col004c": "'+aJSon[04]+'",' + enter
            _cRetJson := _cRetJson + '"col005c": "'+aJSon[05]+'",' + enter
            _cRetJson := _cRetJson + '"col006n": '+Str(aJSon[06])+',' + enter
            _cRetJson := _cRetJson + '"col007n": '+Str(aJSon[07])+',' + enter
            _cRetJson := _cRetJson + '"col008n": '+Str(aJSon[08])+',' + enter
            _cRetJson := _cRetJson + '"col009c": "'+aJSon[09]+'",' + enter
            _cRetJson := _cRetJson + '"col010c": "'+aJSon[10]+'",' + enter
            _cRetJson := _cRetJson + '"col011c": "'+aJSon[11]+'",' + enter
            _cRetJson := _cRetJson + '"col012n": '+Str(aJSon[12])+',' + enter
            _cRetJson := _cRetJson + '"col013c": "'+aJSon[13]+'",' + enter
            _cRetJson := _cRetJson + '"col014d": "'+aJSon[14]+'",' + enter
            _cRetJson := _cRetJson + '"col015c": "'+aJSon[15]+'",' + enter
            _cRetJson := _cRetJson + '"col016n": '+Str(aJSon[16])+',' + enter
            _cRetJson := _cRetJson + '"col017c": "'+aJSon[17]+'",' + enter
            _cRetJson := _cRetJson + '"col018c": "'+aJSon[18]+'",' + enter
            _cRetJson := _cRetJson + '"col019c": "'+aJSon[19]+'",' + enter
            _cRetJson := _cRetJson + '"col020c": "'+aJSon[20]+'",' + enter
            _cRetJson := _cRetJson + '"col021c": "'+aJSon[21]+'",' + enter
            _cRetJson := _cRetJson + '"col022c": "'+aJSon[22]+'",' + enter
            _cRetJson := _cRetJson + '"col023c": "'+aJSon[23]+'",' + enter
            _cRetJson := _cRetJson + '"col024d": "'+aJSon[24]+'",' + enter
            _cRetJson := _cRetJson + '"col025c": "'+aJSon[25]+'",' + enter
            _cRetJson := _cRetJson + '"col026c": "'+aJSon[26]+'",' + enter
            _cRetJson := _cRetJson + '"col027c": "'+aJSon[27]+'",' + enter
            _cRetJson := _cRetJson + '"col028c": "'+aJSon[28]+'",' + enter
            _cRetJson := _cRetJson + '"col029c": "'+aJSon[29]+'",' + enter
            _cRetJson := _cRetJson + '"col030c": "'+aJSon[30]+'",' + enter
            _cRetJson := _cRetJson + '"col031c": "'+aJSon[31]+'",' + enter
            _cRetJson := _cRetJson + '"col032c": "L",' + enter
            _cRetJson := _cRetJson + '"col033c": "'+cNumero+'",' + enter
            _cRetJson := _cRetJson + '"col034c": "'+SCP->CP_ITEM+'",' + enter
            _cRetJson := _cRetJson + '"col035n": '+Str(aJSon[35])+',' + enter
            _cRetJson := _cRetJson + '"col036n": '+Str(aJSon[36])+',' + enter
            _cRetJson := _cRetJson + '"col037c": "'+aJSon[37]+'",' + enter
            _cRetJson := _cRetJson + '"col038d": "'+aJSon[38]+'",' + enter
            _cRetJson := _cRetJson + '"col039d": "'+aJSon[39]+'",' + enter
            _cRetJson := _cRetJson + '"col040d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter
            _cRetJson := _cRetJson + '"col041c": "", ' + enter
            _cRetJson := _cRetJson + '"col042c": "NI",' + enter
            _cRetJson := _cRetJson + '"col043d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'"' + enter

            If _nIJson == _nTamJson
               _cRetJson := _cRetJson + '}' + enter
            Else
               _cRetJson := _cRetJson + '},' + enter
            EndIf
         Else
            _cRetJson := _cRetJson + '{' + enter
            _cRetJson := _cRetJson + '"col001n": '+AllTrim(Str(aJSon[01]))+',' + enter
            _cRetJson := _cRetJson + '"col002c": "'+aJSon[02]+'",' + enter
            _cRetJson := _cRetJson + '"col003c": "'+aJSon[03]+'",' + enter
            _cRetJson := _cRetJson + '"col004c": "'+aJSon[04]+'",' + enter
            _cRetJson := _cRetJson + '"col005c": "'+aJSon[05]+'",' + enter
            _cRetJson := _cRetJson + '"col006n": '+Str(aJSon[06])+',' + enter
            _cRetJson := _cRetJson + '"col007n": '+Str(aJSon[07])+',' + enter
            _cRetJson := _cRetJson + '"col008n": '+Str(aJSon[08])+',' + enter
            _cRetJson := _cRetJson + '"col009c": "'+aJSon[09]+'",' + enter
            _cRetJson := _cRetJson + '"col010c": "'+aJSon[10]+'",' + enter
            _cRetJson := _cRetJson + '"col011c": "'+aJSon[11]+'",' + enter
            _cRetJson := _cRetJson + '"col012n": '+Str(aJSon[12])+',' + enter
            _cRetJson := _cRetJson + '"col013c": "'+aJSon[13]+'",' + enter
            _cRetJson := _cRetJson + '"col014d": "'+aJSon[14]+'",' + enter
            _cRetJson := _cRetJson + '"col015c": "'+aJSon[15]+'",' + enter
            _cRetJson := _cRetJson + '"col016n": '+Str(aJSon[16])+',' + enter
            _cRetJson := _cRetJson + '"col017c": "'+aJSon[17]+'",' + enter
            _cRetJson := _cRetJson + '"col018c": "'+aJSon[18]+'",' + enter
            _cRetJson := _cRetJson + '"col019c": "'+aJSon[19]+'",' + enter
            _cRetJson := _cRetJson + '"col020c": "'+aJSon[20]+'",' + enter
            _cRetJson := _cRetJson + '"col021c": "'+aJSon[21]+'",' + enter
            _cRetJson := _cRetJson + '"col022c": "'+aJSon[22]+'",' + enter
            _cRetJson := _cRetJson + '"col023c": "'+aJSon[23]+'",' + enter
            _cRetJson := _cRetJson + '"col024d": "'+aJSon[24]+'",' + enter
            _cRetJson := _cRetJson + '"col025c": "'+aJSon[25]+'",' + enter
            _cRetJson := _cRetJson + '"col026c": "'+aJSon[26]+'",' + enter
            _cRetJson := _cRetJson + '"col027c": "'+aJSon[27]+'",' + enter
            _cRetJson := _cRetJson + '"col028c": "'+aJSon[28]+'",' + enter
            _cRetJson := _cRetJson + '"col029c": "'+aJSon[29]+'",' + enter
            _cRetJson := _cRetJson + '"col030c": "'+aJSon[30]+'",' + enter
            _cRetJson := _cRetJson + '"col031c": "'+aJSon[31]+'",' + enter
            _cRetJson := _cRetJson + '"col032c": "L",' + enter
            _cRetJson := _cRetJson + '"col033c": "'+cNumero+'",' + enter
            _cRetJson := _cRetJson + '"col034c": "'+StrZero(_nIJson,2)+'",' + enter
            _cRetJson := _cRetJson + '"col035n": '+Str(aJSon[35])+',' + enter
            _cRetJson := _cRetJson + '"col036n": '+Str(aJSon[36])+',' + enter
            _cRetJson := _cRetJson + '"col037c": "'+aJSon[37]+'",' + enter
            _cRetJson := _cRetJson + '"col038d": "'+aJSon[38]+'",' + enter
            _cRetJson := _cRetJson + '"col039d": "'+aJSon[39]+'",' + enter
            _cRetJson := _cRetJson + '"col040d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter
            _cRetJson := _cRetJson + '"col041c": "", ' + enter
            _cRetJson := _cRetJson + '"col042c": "NI",' + enter
            _cRetJson := _cRetJson + '"col043d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'"' + enter

            If _nIJson == _nTamJson
               _cRetJson := _cRetJson + '}' + enter
            Else
               _cRetJson := _cRetJson + '},' + enter
            EndIf

            Aadd( aItens, {} )
            Aadd( aItens[ Len( aItens ) ],{"CP_ITEM"    ,StrZero(_nIJson,2), Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_PRODUTO" ,aJSon[09]  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_LOCAL"   ,aJSon[15]  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_QUANT"   ,aJSon[12]  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_CC"      ,aJSon[17]  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_OBS"     ,aJSon[11]  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_NUMOS"   ,AllTrim(Str(aJSon[07]))  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_XIDPIMS" ,AllTrim(Str(aJSon[01]))  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_XORPIMS" ,"041M"  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_X_CCGER" ,GetNewPar("MV_X_CCGER", "")  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_X_CCACU" ,GetNewPar("MV_X_CCA", "")  , Nil } )
         EndIf
      EndIf

      If _nIJson == _nTamJson
         _cRetJson := _cRetJson + ']' + enter
         ::setResponse(_cRetJson)
      EndIf
      _nIJson++
   EndDo

   If !Empty(aCab) .and. !Empty(aItens)
      SB1->(DbSetOrder(1))
      SCP->(DbSetOrder(1))
      MsExecAuto( { | x, y, z | Mata105( x, y , z ) }, aCab, aItens , nOpcx )

      If !lMsErroAuto
         If nOpcx == 3
            While ( GetSx8Len() > nSaveSx8 )
               ConfirmSx8()
            EndDo
         EndIf
         //::setResponse(_cRetJson)
      Else
         If nOpcx == 3 .and. !__lSX8
            RollBackSx8()
         EndIf

         conOut(OemToAnsi("Erro na inclusao"))
         //aLog := getAutoGRLog()
         aLog := MostraErro()
         ::cRet := "ERRO" + enter
         //for i := 1 to len(aLog)
         ::cRet += aLog + enter
         //next i
         conout(enter + ::cRet + enter)
         ::setResponse('{') 
         ::setResponse( '"Retorno apos execucao": "' + ::cRet + '"')
         ::setResponse('}')
         lInclui := .F.
         DisarmTransaction()
         break
      EndIf
   EndIf
Else
   AAdd(aJSon,ValInfo(oParseJSON:COL001N,"N")) //Identificador exclusivo (PK) - Número sequencial
   AAdd(aJSon,ValInfo(oParseJSON:COL002C,"C")) //Módulo origem - PIMS-MI = Manut. Industrial; MANCRO = Manut. Automotiva
   AAdd(aJSon,ValInfo(oParseJSON:COL003C,"C")) //Empresa (MI) ou Instância (MANFRO) do PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL004C,"C")) //Código da empresa/organização no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL005C,"C")) //Código da filial/estabelecimento no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL006N,"N")) //Identificador no MI (id_ospecprev)
   AAdd(aJSon,ValInfo(oParseJSON:COL007N,"N")) //Número do Boletim (MANFRO) ou OS (MI)
   AAdd(aJSon,ValInfo(oParseJSON:COL008N,"N")) //Número da sequência
   AAdd(aJSon,ValInfo(oParseJSON:COL009C,"C")) //Código do item no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL010C,"C")) //Descrição do item
   AAdd(aJSon,ValInfo(oParseJSON:COL011C,"C")) //Detalhamento do Material/Serviço
   AAdd(aJSon,ValInfo(oParseJSON:COL012N,"N")) //Quantidade solicitada
   AAdd(aJSon,ValInfo(oParseJSON:COL013C,"C")) //Unidade de medida
   AAdd(aJSon,ValInfo(oParseJSON:COL014D,"C")) //Data da solicitação
   AAdd(aJSon,ValInfo(oParseJSON:COL015C,"C")) //Depósito da requisição e baixa do item quando for requisição interna
   AAdd(aJSon,ValInfo(oParseJSON:COL016N,"N")) //Custo unitário previsto para o item - Default 0
   AAdd(aJSon,ValInfo(oParseJSON:COL017C,"C")) //Código do centro de custo do ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL018C,"C")) //Tipo do movimento - Sempre "S"
   AAdd(aJSon,ValInfo(oParseJSON:COL019C,"C")) //Tipo do documento a ser gerado no ERP - "R" = Requisição interna; "S" = Solic. Compra Material; "X" = Solic. Compra Serviço
   AAdd(aJSon,ValInfo(oParseJSON:COL020C,"C")) //Código Investimento
   AAdd(aJSon,ValInfo(oParseJSON:COL021C,"C")) //Tipo de aplicação - "M" = Manutenção; "I" = Investimento.
   AAdd(aJSon,ValInfo(oParseJSON:COL022C,"C")) //Usuário solicitante
   AAdd(aJSon,ValInfo(oParseJSON:COL023C,"C")) //Equipe solicitante
   AAdd(aJSon,ValInfo(oParseJSON:COL024D,"C")) //Data prevista de utilização
   AAdd(aJSon,ValInfo(oParseJSON:COL025C,"C")) //Informa se haverá inspeção interna - "S" = Sim; "N" = Não
   AAdd(aJSon,ValInfo(oParseJSON:COL026C,"C")) //Informa se haverá inspeção externa - "S" = Sim; "N" = Não
   AAdd(aJSon,ValInfo(oParseJSON:COL027C,"C")) //Detalhamento da inspeção
   AAdd(aJSon,ValInfo(oParseJSON:COL028C,"C")) //Comentário sobre o item em questão
   AAdd(aJSon,ValInfo(oParseJSON:COL029C,"C")) //Comentário ao comprador
   AAdd(aJSon,ValInfo(oParseJSON:COL030C,"C")) //Código do crachá do solicitante
   AAdd(aJSon,ValInfo(oParseJSON:COL031C,"C")) //Informa se efetua a baixa automaticamente - Default "N"
   AAdd(aJSon,ValInfo(oParseJSON:COL032C,"C")) //Situação do lançamento - Inserido pelo PIMS e atualizado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL033C,"C")) //Número do documento no ERP - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL034C,"C")) //Item do documento no ERP - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL035N,"N")) //Número da solicitação - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL036N,"N")) //Número do pedido - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL037C,"C")) //Nome do comprador - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL038D,"C")) //Previsão de entrega - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL039D,"C")) //Data e hora do envio do PIMS para a tabela intermediária - Sysdate
   AAdd(aJSon,ValInfo(oParseJSON:COL040D,"C")) //Data e hora da integração no ERP - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL041C,"C")) //Mensagem de retorno de inconsistência - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL042C,"C"))

   SB1->(DbSetOrder(1))
   If !SB1->(DbSeek(xFilial("SB1")+Padr(aJSon[09],TamSx3("B1_COD")[1])))
      _lTdOk := .F.
      _cRetInco := "PRODUTO (SB1) NAO LOCALIZADO"
   Else
      NNR->(DbSetOrder(1))
      If !NNR->(DbSeek(xFilial("NNR")+Padr(aJSon[15],TamSx3("NNR_CODIGO")[1])))
         _lTdOk := .F.
         _cRetInco := "ALMOXARIFADO (NNR) NAO LOCALIZADO"
      Else
         SB2->(DbSetOrder(1))
         If !SB2->(DbSeek(xFilial("SB2")+Padr(aJSon[09],TamSx3("B2_COD")[1])+Padr(aJSon[15],TamSx3("B2_LOCAL")[1])))
            _lTdOk := .F.
            _cRetInco := "PRODUTO + ALMOXARIFADO (SB2) NAO LOCALIZADO"
         Else
            CTT->(DbSetOrder(1))
            If !CTT->(DbSeek(xFilial("CTT")+Padr(aJSon[17],TamSx3("CTT_CUSTO")[1])))
               _lTdOk    := .F.
               _cRetInco := "CENTRO DE CUSTO (CTT) NAO LOCALIZADO"
            EndIf
         EndIf
      EndIf
   EndIf
      
   If !_lTdOk
      conOut(enter + oemToAnsi("Erro na busca de registro na inclusao! ") + enter)

      ::cRet := "Erro na busca de registro na inclusao "
      ::setResponse('{' + enter) 
      ::setResponse( '"col001n": '+AllTrim(Str(aJSon[01]))+',' + enter)
      ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
      ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
      ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
      ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
      ::setResponse( '"col006n": '+Str(aJSon[06])+',' + enter)
      ::setResponse( '"col007n": '+Str(aJSon[07])+',' + enter)
      ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
      ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
      ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
      ::setResponse( '"col011c": "'+aJSon[11]+'",' + enter)
      ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
      ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
      ::setResponse( '"col014d": "'+aJSon[14]+'",' + enter)
      ::setResponse( '"col015c": "'+aJSon[15]+'",' + enter)
      ::setResponse( '"col016n": '+Str(aJSon[16])+',' + enter)
      ::setResponse( '"col017c": "'+aJSon[17]+'",' + enter)
      ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
      ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
      ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
      ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
      ::setResponse( '"col022c": "'+aJSon[22]+'",' + enter)
      ::setResponse( '"col023c": "'+aJSon[23]+'",' + enter)
      ::setResponse( '"col024d": "'+aJSon[24]+'",' + enter)
      ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
      ::setResponse( '"col026c": "'+aJSon[26]+'",' + enter)
      ::setResponse( '"col027c": "'+aJSon[27]+'",' + enter)
      ::setResponse( '"col028c": "'+aJSon[28]+'",' + enter)
      ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
      ::setResponse( '"col030c": "'+aJSon[30]+'",' + enter)
      ::setResponse( '"col031c": "'+aJSon[31]+'",' + enter)
      ::setResponse( '"col032c": "ER",' + enter)
      ::setResponse( '"col033c": "",' + enter)
      ::setResponse( '"col034c": "",' + enter)
      ::setResponse( '"col035n": '+Str(aJSon[35])+',' + enter)
      ::setResponse( '"col036n": '+Str(aJSon[36])+',' + enter)
      ::setResponse( '"col037c": "'+aJSon[37]+'",' + enter)
      ::setResponse( '"col038d": "'+aJSon[38]+'",' + enter)
      ::setResponse( '"col039d": "'+aJSon[39]+'",' + enter)
      ::setResponse( '"col040d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
      ::setResponse( '"col041c": "'+_cRetInco+'", ' + enter)
      ::setResponse( '"col042c": "NI",' + enter)
      ::setResponse( '"col043d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'"' + enter)
      ::setResponse('}' + enter)
   Else
      SCP->(DbOrderNickName("XIDPIMSPRO"))
      If SCP->(DbSeek(xFilial("SCP")+Padr(AllTrim(Str(aJSon[01])),TamSx3("CP_XIDPIMS")[1])+Padr(aJSon[09],TamSx3("CP_PRODUTO")[1])))
         cNumero := SCP->CP_NUM
         conOut(enter + oemToAnsi("Registro ja existe! Codigo: ") + cNumero + enter)

         ::cRet := "Registro ja existe! Codigo: " + cNumero
         ::setResponse('{' + enter) 
         ::setResponse( '"col001n": '+AllTrim(Str(aJSon[01]))+',' + enter)
         ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
         ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
         ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
         ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
         ::setResponse( '"col006n": '+Str(aJSon[06])+',' + enter)
         ::setResponse( '"col007n": '+Str(aJSon[07])+',' + enter)
         ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
         ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
         ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
         ::setResponse( '"col011c": "'+aJSon[11]+'",' + enter)
         ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
         ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
         ::setResponse( '"col014d": "'+aJSon[14]+'",' + enter)
         ::setResponse( '"col015c": "'+aJSon[15]+'",' + enter)
         ::setResponse( '"col016n": '+Str(aJSon[16])+',' + enter)
         ::setResponse( '"col017c": "'+aJSon[17]+'",' + enter)
         ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
         ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
         ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
         ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
         ::setResponse( '"col022c": "'+aJSon[22]+'",' + enter)
         ::setResponse( '"col023c": "'+aJSon[23]+'",' + enter)
         ::setResponse( '"col024d": "'+aJSon[24]+'",' + enter)
         ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
         ::setResponse( '"col026c": "'+aJSon[26]+'",' + enter)
         ::setResponse( '"col027c": "'+aJSon[27]+'",' + enter)
         ::setResponse( '"col028c": "'+aJSon[28]+'",' + enter)
         ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
         ::setResponse( '"col030c": "'+aJSon[30]+'",' + enter)
         ::setResponse( '"col031c": "'+aJSon[31]+'",' + enter)
         ::setResponse( '"col032c": "L",' + enter)
         ::setResponse( '"col033c": "'+cNumero+'",' + enter)
         ::setResponse( '"col034c": "'+SCP->CP_ITEM+'",' + enter)
         ::setResponse( '"col035n": '+Str(aJSon[35])+',' + enter)
         ::setResponse( '"col036n": '+Str(aJSon[36])+',' + enter)
         ::setResponse( '"col037c": "'+aJSon[37]+'",' + enter)
         ::setResponse( '"col038d": "'+aJSon[38]+'",' + enter)
         ::setResponse( '"col039d": "'+aJSon[39]+'",' + enter)
         ::setResponse( '"col040d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
         ::setResponse( '"col041c": "", ' + enter)
         ::setResponse( '"col042c": "NI",' + enter)
         ::setResponse( '"col043d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'"' + enter)
         ::setResponse('}' + enter)
      Else

         nSaveSx8 := GetSx8Len()
         cNumero  := GetSx8Num('SCP','CP_NUM')

         DbSelectArea('SCP')
         SCP->(DbSetOrder(1))

         If nOpcx == 3
            While SCP->( DbSeek(xFilial('SCP')+cNumero))
               ConfirmSx8()
               cNumero := GetSx8Num('SCP','CP_NUM')
            EndDo
         EndIf

         Aadd(aCab,{"CP_NUM"     ,cNumero   , Nil })
         Aadd(aCab,{"CP_EMISSAO" ,dDataBase , Nil })
         Aadd(aCab,{"CP_SOLICIT" ,aJSon[22] , Nil })

         Aadd( aItens, {} )
         Aadd( aItens[ Len( aItens ) ],{"CP_ITEM"    ,'01'       , Nil } )
         Aadd( aItens[ Len( aItens ) ],{"CP_PRODUTO" ,aJSon[09]  , Nil } )
         Aadd( aItens[ Len( aItens ) ],{"CP_LOCAL"   ,aJSon[15]  , Nil } )
         Aadd( aItens[ Len( aItens ) ],{"CP_QUANT"   ,aJSon[12]  , Nil } )
         Aadd( aItens[ Len( aItens ) ],{"CP_CC"      ,aJSon[17]  , Nil } )
         Aadd( aItens[ Len( aItens ) ],{"CP_OBS"     ,aJSon[11]  , Nil } )
         Aadd( aItens[ Len( aItens ) ],{"CP_NUMOS"   ,AllTrim(Str(aJSon[07]))  , Nil } )
         Aadd( aItens[ Len( aItens ) ],{"CP_XIDPIMS" ,AllTrim(Str(aJSon[01]))  , Nil } )
         Aadd( aItens[ Len( aItens ) ],{"CP_XORPIMS" ,"041M"  , Nil } )

         SB1->(DbSetOrder(1))
         SCP->(DbSetOrder(1))
         MsExecAuto( { | x, y, z | Mata105( x, y , z ) }, aCab, aItens , nOpcx )

         If !lMsErroAuto
            While ( GetSx8Len() > nSaveSx8 )
               ConfirmSx8()
            EndDo

            conOut(enter + oemToAnsi("Incluido com sucesso! ") + cNumero + enter)

            ::cRet := "Incluido com sucesso : Codigo: " + cNumero
            ::setResponse('{' + enter) 
            ::setResponse( '"col001n": '+AllTrim(Str(aJSon[01]))+',' + enter)
            ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
            ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
            ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
            ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
            ::setResponse( '"col006n": '+Str(aJSon[06])+',' + enter)
            ::setResponse( '"col007n": '+Str(aJSon[07])+',' + enter)
            ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
            ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
            ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
            ::setResponse( '"col011c": "'+aJSon[11]+'",' + enter)
            ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
            ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
            ::setResponse( '"col014d": "'+aJSon[14]+'",' + enter)
            ::setResponse( '"col015c": "'+aJSon[15]+'",' + enter)
            ::setResponse( '"col016n": '+Str(aJSon[16])+',' + enter)
            ::setResponse( '"col017c": "'+aJSon[17]+'",' + enter)
            ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
            ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
            ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
            ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
            ::setResponse( '"col022c": "'+aJSon[22]+'",' + enter)
            ::setResponse( '"col023c": "'+aJSon[23]+'",' + enter)
            ::setResponse( '"col024d": "'+aJSon[24]+'",' + enter)
            ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
            ::setResponse( '"col026c": "'+aJSon[26]+'",' + enter)
            ::setResponse( '"col027c": "'+aJSon[27]+'",' + enter)
            ::setResponse( '"col028c": "'+aJSon[28]+'",' + enter)
            ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
            ::setResponse( '"col030c": "'+aJSon[30]+'",' + enter)
            ::setResponse( '"col031c": "'+aJSon[31]+'",' + enter)
            ::setResponse( '"col032c": "L",' + enter)
            ::setResponse( '"col033c": "'+cNumero+'",' + enter)
            ::setResponse( '"col034c": "01",' + enter)
            ::setResponse( '"col035n": '+Str(aJSon[35])+',' + enter)
            ::setResponse( '"col036n": '+Str(aJSon[36])+',' + enter)
            ::setResponse( '"col037c": "'+aJSon[37]+'",' + enter)
            ::setResponse( '"col038d": "'+aJSon[38]+'",' + enter)
            ::setResponse( '"col039d": "'+aJSon[39]+'",' + enter)
            ::setResponse( '"col040d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
            ::setResponse( '"col041c": "", ' + enter)
            ::setResponse( '"col042c": "NI",' + enter)
            ::setResponse( '"col043d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'"' + enter)
            ::setResponse('}' + enter)
         Else
            If !__lSX8
               RollBackSx8()
            EndIf

            conOut(OemToAnsi("Erro na inclusao"))
            //aLog := getAutoGRLog()
            aLog := MostraErro()
            ::cRet := "ERRO" + enter
            //for i := 1 to len(aLog)
            ::cRet += aLog + enter
            //next i
            conout(enter + ::cRet + enter)
            ::setResponse('{') 
            ::setResponse( '"Retorno apos execucao": "' + ::cRet + '"')
            ::setResponse('}')
            lInclui := .F.
            DisarmTransaction()
            break
         EndIf
      EndIf
   EndIf
EndIf

END TRANSACTION

RpcClearEnv()

Return .t.


/*/{Protheus.doc} PIMS032M
Serviço POST para Baixa de Consumiveis
@author Max Ivan
@since 01/09/19
@version P12
@uso MP12
@type function
/*/
WSRESTFUL INT_PIMS_032M DESCRIPTION "Serviço REST para Baixa de Consumiveis"

//COLOCAR CAMPOS OBRIGATORIOS ABAIXO
WSDATA cRet		AS STRING

WSMETHOD POST DESCRIPTION "POST / Baixa de Consumiveis" WSSYNTAX ""

END WSRESTFUL

WSMETHOD POST WSRECEIVE RECEIVE WSSERVICE INT_PIMS_032M

Local aJSon         := {}
Local aLog		    := {}
Local cJson         := ::getContent()
Local cUniEmp		:= 	""
Local cFilEmp		:= 	""
Local lInclui       := .T.
Local _lTdOk        := .T.
Local _cRetInco     := ""
Local _cRetJson     := ""

Local aCab          := {}
Local aItens        := {}
Local nSaveSx8      := 0
Local cNumero       := ''

Local nOpcx         := 3

Local nCount        := 1

Private lMsErroAuto    := .F.
Private lMsErroHelp    := .T.
Private lAutoErrNoFile := .T.

oParseJSON := nil

::setContentType("application/json")
FWJsonDeserialize(DecodeUtf8(cJson), @oParseJSON)

If ValType(oParseJSON) == "A" //json com mais de 1 linha
   cUniEmp := oParseJSON[1]:col011c
   cFilEmp := oParseJSON[1]:col012c
Else
   cUniEmp := oParseJSON:col011c
   cFilEmp := oParseJSON:col012c
EndIf

RpcSetType(3)
RpcSetEnv(cUniEmp,cFilEmp,"","","EST")
cEmpAnt := cUniEmp
cFilAnt := cFilEmp

BEGIN TRANSACTION  

If ValType(oParseJSON) == "A" //json com mais de 1 linha
   _nIJson   := 1
   _nTamJson := Len(oParseJSON)
   While _nIJson <= _nTamJson
      aJSon := {}
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL001N,"N")) //ID Sequence S_ID_ENV_CODID - PK da tabela
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL002C,"C")) //Origem dos dados no PIMS
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL003C,"C")) //Código da instância/empresa PIMS
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL004N,"N")) //Boletim/identificador do apontamento no PIMS
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL005N,"N")) //Sequência do apontamento no PIMS
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL006C,"C")) //Código PIMS do material consumido
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL007D,"C")) //Data do movimento do consumo
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL008N,"N")) //Número da OS no PIMS
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL009N,"N")) //Código PIMS do centro de custo
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL010C,"C")) //Tipo do movimento
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL011C,"C")) //Código da empresa/organização no ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL012C,"C")) //Código da filial/estabelecimento no ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL013C,"C")) //Código ERP do material consumido
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL014N,"N")) //Quantidade do consumo
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL015C,"C")) //Código ERP da unidade de medida
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL016C,"C")) //Código ERP do centro de custo
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL017C,"C")) //Deposito ERP para o depósito - Armazém a dar a baixa
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL018C,"C")) //Usuário do apontamento
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL019C,"C")) //Status de leitura
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL020C,"C")) //Documento gerado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL021N,"N")) //Custo total da transação
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL022C,"C")) //Registro estornado ou não - "S" = Sim; "N" = Não
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL023C,"C")) //Documento ERP que foi estornado pelo movimento ENV_TIPMOV = "E"
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL024C,"C")) //Mensagem de log da integração
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL025D,"C")) //Data do envio pelo PIMS
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL026D,"C")) //Data de integração pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL027D,"C")) //Data de integração do custo pelo PIMS
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL028D,"C")) //Data e hora leitura do Webservice

      _cRetInco := ""

      If aJSon[10] == "E"
         If !Empty(aJSon[23])
            SCP->(DbSetOrder(1))
            If !SCP->(DbSeek(xFilial("SCP")+aJSon[23]))
               _lTdOk := .F.
               _cRetInco := "NAO LOCALIZADO A SA "+aJSon[23]+" PARA EXCLUSAO"
            Else
               //Verifica se o Item ja esta baixado, entao exclui a baixa primeiro
               SCP->(DbSetOrder(1))
               If SCP->(DbSeek(xFilial("SCP")+SubsTr(aJSon[23],1,8)))
                  If SCP->CP_QUJE > 0
                     aCamposSCP := { {"CP_NUM"  ,SCP->CP_NUM ,Nil },;
                                     {"CP_ITEM"  ,SCP->CP_ITEM ,Nil },;
                                     {"CP_QUANT" ,SCP->CP_QUANT ,Nil }}

                     aCamposSD3 := { {"D3_TM"      ,"501"                       ,Nil },; // Tipo do Mov.
                                     {"D3_COD"     ,SCP->CP_PRODUTO             ,Nil },;
                                     {"D3_LOCAL"   ,SCP->CP_LOCAL               ,Nil },;
                                     {"D3_DOC"     ,""                          ,Nil },; // No.do Docto.
                                     {"D3_EMISSAO" ,DDATABASE                   ,Nil },;
                                     {"D3_X_CCGER" ,GetNewPar("MV_X_CCGER", "") ,Nil },;
                                     {"D3_X_CCACU" ,If(AllTrim(aJSon[02]) == "CS_MNFABAS",GetNewPar("MV_X_CCD", ""),GetNewPar("MV_X_CCA", "")) ,Nil }}

                     aRelProj := {}

                     lMSHelpAuto := .F.
                     lMsErroAuto := .F.

                     MSExecAuto({|v,x,y,z,w| mata185(v,x,y,z,w)},aCamposSCP,aCamposSD3,2,,aRelProj)   // 1 = BAIXA (ROT.AUT)

                     If lMsErroAuto
                        _lTdOk := .F.
                        _cRetInco := "NAO FOI POSSIVEL ESTORNAR AS BAIXAS DA SA "+aJSon[23]
                     Else
                        SCP->(DbSetOrder(1))
                        If SCP->(DbSeek(xFilial("SCP")+SubsTr(aJSon[23],1,8)))
                           If RecLock("SCP",.F.)
                              SCP->CP_OK      := ""
                              SCP->CP_PREREQU := ""
                              SCP->(MsUnLock())
                           EndIf
                        EndIf
                        //MsgInfo("Estorno com sucesso!!!")
                     EndIF
                  EndIf
               EndIf
            EndIf
         Else
            _lTdOk := .F.
            _cRetInco := "COL023C ESTA EM BRANCO. PARA EXCLUSAO E NECESSARIO O PREENCHIMENTO DESTA."
         EndIf
      Else
         SCP->(DbOrderNickName("XIDPIMSPRO"))
         If !SCP->(DbSeek(xFilial("SCP")+Padr(AllTrim(Str(aJSon[01])),TamSx3("CP_XIDPIMS")[1])))
            SB1->(DbSetOrder(1))
            If !SB1->(DbSeek(xFilial("SB1")+Padr(aJSon[13],TamSx3("B1_COD")[1])))
               _lTdOk := .F.
               _cRetInco := "PRODUTO (SB1) NAO LOCALIZADO"
            Else
               NNR->(DbSetOrder(1))
               If !NNR->(DbSeek(xFilial("NNR")+Padr(aJSon[17],TamSx3("NNR_CODIGO")[1])))
                  _lTdOk := .F.
                  _cRetInco := "ALMOXARIFADO (NNR) NAO LOCALIZADO"
               Else
                  SB2->(DbSetOrder(1))
                  If !SB2->(DbSeek(xFilial("SB2")+Padr(aJSon[13],TamSx3("B2_COD")[1])+Padr(aJSon[17],TamSx3("B2_LOCAL")[1])))
                     IncSB9(aJSon[13],aJSon[17],0)
                     SB2->(DbSetOrder(1))
                     If !SB2->(DbSeek(xFilial("SB2")+Padr(aJSon[13],TamSx3("B2_COD")[1])+Padr(aJSon[17],TamSx3("B2_LOCAL")[1])))
                        _lTdOk := .F.
                        _cRetInco := "PRODUTO + ALMOXARIFADO (SB2) NAO LOCALIZADO"
                     EndIf
                  Else
                     CTT->(DbSetOrder(1))
                     If !CTT->(DbSeek(xFilial("CTT")+Padr(aJSon[16],TamSx3("CTT_CUSTO")[1])))
                        _lTdOk    := .F.
                        _cRetInco := "CENTRO DE CUSTO (CTT) NAO LOCALIZADO"
                     EndIf
                  EndIf
               EndIf
            EndIf
         Else
            _lTdOk    := .F.
            _cRetInco := "JA EXISTE INSERCAO COM ESTE ID"
         EndIf
      EndIf

      If Empty(aCab) .and. _lTdOk
         If aJSon[10] == "E"
            Aadd(aCab,{"CP_NUM"     ,SubsTr(aJSon[23],1,6) , Nil })
            nOpcx := 4
         Else
            nSaveSx8 := GetSx8Len()
            cNumero  := GetSx8Num('SCP','CP_NUM')

            DbSelectArea('SB1')
            SB1->(DbSetOrder(1))

            DbSelectArea('SCP')
            SCP->(DbSetOrder(1))

            If nOpcx == 3
               While SCP->( DbSeek(xFilial('SCP')+cNumero))
                  ConfirmSx8()
                  cNumero := GetSx8Num('SCP','CP_NUM')
               EndDo
            EndIf

            dDataBase := CtoD(SubsTr(aJSon[07],1,10))
            Aadd(aCab,{"CP_NUM"     ,cNumero   , Nil })
            Aadd(aCab,{"CP_EMISSAO" ,CtoD(SubsTr(aJSon[07],1,10)) , Nil })
            Aadd(aCab,{"CP_SOLICIT" ,aJSon[18] , Nil })
         EndIf
      EndIf

      If _nIJson == 1
         ::cRet := "Processo em Lote "
         _cRetJson := _cRetJson + '[' + enter
      EndIf
      If !_lTdOk
         conOut(enter + oemToAnsi("Erro na busca de informacoes! ") + enter)

         _cRetJson := _cRetJson + '{' + enter
         _cRetJson := _cRetJson + '"col001n": '+Str(aJSon[01])+',' + enter
         _cRetJson := _cRetJson + '"col002c": "'+aJSon[02]+'",' + enter
         _cRetJson := _cRetJson + '"col003c": "'+aJSon[03]+'",' + enter
         _cRetJson := _cRetJson + '"col004n": '+Str(aJSon[04])+',' + enter
         _cRetJson := _cRetJson + '"col005n": '+Str(aJSon[05])+',' + enter
         _cRetJson := _cRetJson + '"col006c": "'+aJSon[06]+'",' + enter
         _cRetJson := _cRetJson + '"col007d": "'+aJSon[07]+'",' + enter
         _cRetJson := _cRetJson + '"col008n": '+Str(aJSon[08])+',' + enter
         _cRetJson := _cRetJson + '"col009n": '+Str(aJSon[09])+',' + enter
         _cRetJson := _cRetJson + '"col010c": "'+aJSon[10]+'",' + enter
         _cRetJson := _cRetJson + '"col011c": "'+aJSon[11]+'",' + enter
         _cRetJson := _cRetJson + '"col012c": "'+aJSon[12]+'",' + enter
         _cRetJson := _cRetJson + '"col013c": "'+aJSon[13]+'",' + enter
         _cRetJson := _cRetJson + '"col014n": '+Str(aJSon[14])+',' + enter
         _cRetJson := _cRetJson + '"col015c": "'+aJSon[15]+'",' + enter
         _cRetJson := _cRetJson + '"col016c": "'+aJSon[16]+'",' + enter
         _cRetJson := _cRetJson + '"col017c": "'+aJSon[17]+'",' + enter
         _cRetJson := _cRetJson + '"col018c": "'+aJSon[18]+'",' + enter
         _cRetJson := _cRetJson + '"col019c": "4",' + enter
         _cRetJson := _cRetJson + '"col020c": "",' + enter
         _cRetJson := _cRetJson + '"col021n": '+Str(aJSon[21])+',' + enter
         _cRetJson := _cRetJson + '"col022c": "'+aJSon[22]+'",' + enter
         _cRetJson := _cRetJson + '"col023c": "'+aJSon[23]+'",' + enter
         _cRetJson := _cRetJson + '"col024c": "'+_cRetInco+'",' + enter
         _cRetJson := _cRetJson + '"col025d": "'+aJSon[25]+'",' + enter
         _cRetJson := _cRetJson + '"col026d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter
         _cRetJson := _cRetJson + '"col027d": "'+aJSon[27]+'",' + enter
         _cRetJson := _cRetJson + '"col028d": "'+aJSon[28]+'"' + enter
         If _nIJson == _nTamJson
            _cRetJson := _cRetJson + '}' + enter
         Else
            _cRetJson := _cRetJson + '},' + enter
         EndIf
      Else
         _cRetJson := _cRetJson + '{' + enter
         _cRetJson := _cRetJson + '"col001n": '+Str(aJSon[01])+',' + enter
         _cRetJson := _cRetJson + '"col002c": "'+aJSon[02]+'",' + enter
         _cRetJson := _cRetJson + '"col003c": "'+aJSon[03]+'",' + enter
         _cRetJson := _cRetJson + '"col004n": '+Str(aJSon[04])+',' + enter
         _cRetJson := _cRetJson + '"col005n": '+Str(aJSon[05])+',' + enter
         _cRetJson := _cRetJson + '"col006c": "'+aJSon[06]+'",' + enter
         _cRetJson := _cRetJson + '"col007d": "'+aJSon[07]+'",' + enter
         _cRetJson := _cRetJson + '"col008n": '+Str(aJSon[08])+',' + enter
         _cRetJson := _cRetJson + '"col009n": '+Str(aJSon[09])+',' + enter
         _cRetJson := _cRetJson + '"col010c": "'+aJSon[10]+'",' + enter
         _cRetJson := _cRetJson + '"col011c": "'+aJSon[11]+'",' + enter
         _cRetJson := _cRetJson + '"col012c": "'+aJSon[12]+'",' + enter
         _cRetJson := _cRetJson + '"col013c": "'+aJSon[13]+'",' + enter
         _cRetJson := _cRetJson + '"col014n": '+Str(aJSon[14])+',' + enter
         _cRetJson := _cRetJson + '"col015c": "'+aJSon[15]+'",' + enter
         _cRetJson := _cRetJson + '"col016c": "'+aJSon[16]+'",' + enter
         _cRetJson := _cRetJson + '"col017c": "'+aJSon[17]+'",' + enter
         _cRetJson := _cRetJson + '"col018c": "'+aJSon[18]+'",' + enter
         _cRetJson := _cRetJson + '"col019c": "2",' + enter
         If nOpcx == 3
            _cRetJson := _cRetJson + '"col020c": "'+cNumero+StrZero(_nIJson,2)+'",' + enter
         Else
            _cRetJson := _cRetJson + '"col020c": "'+aJSon[20]+'",' + enter
         EndIf
         _cRetJson := _cRetJson + '"col021n": '+Str(aJSon[21])+',' + enter
         _cRetJson := _cRetJson + '"col022c": "'+aJSon[22]+'",' + enter
         _cRetJson := _cRetJson + '"col023c": "'+aJSon[23]+'",' + enter
         If nOpcx == 3
            _cRetJson := _cRetJson + '"col024c": "INCLUSAO REALIZADA COM SUCESSO",' + enter
         Else
            _cRetJson := _cRetJson + '"col024c": "EXCLUSAO REALIZADA COM SUCESSO",' + enter
         EndIf
         _cRetJson := _cRetJson + '"col025d": "'+aJSon[25]+'",' + enter
         _cRetJson := _cRetJson + '"col026d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter
         _cRetJson := _cRetJson + '"col027d": "'+aJSon[27]+'",' + enter
         _cRetJson := _cRetJson + '"col028d": "'+aJSon[28]+'"' + enter
         If _nIJson == _nTamJson
            _cRetJson := _cRetJson + '}' + enter
         Else
            _cRetJson := _cRetJson + '},' + enter
         EndIf

         If nOpcx == 3
            Aadd( aItens, {} )
            Aadd( aItens[ Len( aItens ) ],{"CP_ITEM"    ,StrZero(_nIJson,2) , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_PRODUTO" ,aJSon[13]  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_LOCAL"   ,aJSon[17]  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_QUANT"   ,aJSon[14]  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_CC"      ,aJSon[16]  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_OBS"     ,aJSon[11]  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_NUMOS"   ,AllTrim(Str(aJSon[08]))  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_XIDPIMS" ,AllTrim(Str(aJSon[01]))  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_NRBPIMS" ,AllTrim(Str(aJSon[04]))  , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"CP_XORPIMS" ,"032M"  , Nil } )
         Else
            Aadd( aItens, {} )
            Aadd( aItens[ Len( aItens ) ],{"CP_ITEM"    ,SubsTr(aJSon[23],7,2)   , Nil } )
            Aadd( aItens[ Len( aItens ) ],{"AUTDELETA"  ,'S' , Nil } )
         EndIf
      EndIf
      If _nIJson == _nTamJson
         _cRetJson := _cRetJson + ']' + enter
      EndIf
      _nIJson++
   EndDo

   If !Empty(aCab) .and. !Empty(aItens)
      SB1->(DbSetOrder(1))
      SCP->(DbSetOrder(1))
      MsExecAuto( { | x, y, z | Mata105( x, y , z ) }, aCab, aItens , nOpcx )

      If !lMsErroAuto
         If nOpcx == 3
            While ( GetSx8Len() > nSaveSx8 )
               ConfirmSx8()
            EndDo
         Else
            SCP->(DbSetOrder(1))
            If SCP->(DbSeek(xFilial("SCP")+aJSon[23]))
               _cRetJson := StrTran(_cRetJson,"EXCLUSAO REALIZADA COM SUCESSO","NAO REALIZADA EXCLUSAO. SA "+SubsTr(aJSon[23],1,6) + SubsTr(aJSon[23],7,2))
            EndIf
         EndIf
         ::setResponse(_cRetJson)
      Else
         If nOpcx == 3 .and. !__lSX8
            RollBackSx8()
         EndIf

         conOut(OemToAnsi("Erro na inclusao"))
         //aLog := getAutoGRLog()
         aLog := MostraErro()
         ::cRet := "ERRO" + enter
         //for i := 1 to len(aLog)
         ::cRet += aLog + enter
         //next i
         conout(enter + ::cRet + enter)
         ::setResponse('{') 
         ::setResponse( '"Retorno apos execucao": "' + ::cRet + '"')
         ::setResponse('}')
         lInclui := .F.
         DisarmTransaction()
         break
      EndIf
   Else
      conOut(OemToAnsi("Nao processado"))

      ::cRet := "Nao processado"
      ::setResponse(_cRetJson)
   EndIf
Else
   AAdd(aJSon,ValInfo(oParseJSON:COL001N,"N")) //ID Sequence S_ID_ENV_CODID - PK da tabela
   AAdd(aJSon,ValInfo(oParseJSON:COL002C,"C")) //Origem dos dados no PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL003C,"C")) //Código da instância/empresa PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL004N,"N")) //Boletim/identificador do apontamento no PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL005N,"N")) //Sequência do apontamento no PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL006C,"C")) //Código PIMS do material consumido
   AAdd(aJSon,ValInfo(oParseJSON:COL007D,"C")) //Data do movimento do consumo
   AAdd(aJSon,ValInfo(oParseJSON:COL008N,"N")) //Número da OS no PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL009N,"N")) //Código PIMS do centro de custo
   AAdd(aJSon,ValInfo(oParseJSON:COL010C,"C")) //Tipo do movimento
   AAdd(aJSon,ValInfo(oParseJSON:COL011C,"C")) //Código da empresa/organização no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL012C,"C")) //Código da filial/estabelecimento no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL013C,"C")) //Código ERP do material consumido
   AAdd(aJSon,ValInfo(oParseJSON:COL014N,"N")) //Quantidade do consumo
   AAdd(aJSon,ValInfo(oParseJSON:COL015C,"C")) //Código ERP da unidade de medida
   AAdd(aJSon,ValInfo(oParseJSON:COL016C,"C")) //Código ERP do centro de custo
   AAdd(aJSon,ValInfo(oParseJSON:COL017C,"C")) //Deposito ERP para o depósito - Armazém a dar a baixa
   AAdd(aJSon,ValInfo(oParseJSON:COL018C,"C")) //Usuário do apontamento
   AAdd(aJSon,ValInfo(oParseJSON:COL019C,"C")) //Status de leitura
   AAdd(aJSon,ValInfo(oParseJSON:COL020C,"C")) //Documento gerado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL021N,"N")) //Custo total da transação
   AAdd(aJSon,ValInfo(oParseJSON:COL022C,"C")) //Registro estornado ou não - "S" = Sim; "N" = Não
   AAdd(aJSon,ValInfo(oParseJSON:COL023C,"C")) //Documento ERP que foi estornado pelo movimento ENV_TIPMOV = "E"
   AAdd(aJSon,ValInfo(oParseJSON:COL024C,"C")) //Mensagem de log da integração
   AAdd(aJSon,ValInfo(oParseJSON:COL025D,"C")) //Data do envio pelo PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL026D,"C")) //Data de integração pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL027D,"C")) //Data de integração do custo pelo PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL028D,"C")) //Data e hora leitura do webservice

   If aJSon[10] == "E"
      If !Empty(aJSon[23])
         SD3->(DbSetOrder(2))
         If !SD3->(DbSeek(xFilial("SD3")+Padr(aJSon[23],TamSx3("D3_DOC")[1])+Padr(aJSon[13],TamSx3("B1_COD")[1])))
            _lTdOk := .F.
            _cRetInco := "NAO LOCALIZADO O MOV.INTERNO (SD3) "+AllTrim(aJSon[23])+" PRODUTO "+AllTrim(aJSon[13])+" PARA EXCLUSAO"
         Else
            If SD3->D3_ESTORNO == "S"
               _lTdOk := .F.
               _cRetInco := "MOV.INTERNO (SD3) "+AllTrim(aJSon[23])+" PRODUTO "+AllTrim(aJSon[13])+" JA ESTORNADO ANTERIORMENTE!"
            EndIf
         EndIf
      Else
         _lTdOk := .F.
         _cRetInco := "COL023C ESTA EM BRANCO. PARA EXCLUSAO E NECESSARIO O PREENCHIMENTO DESTA."
      EndIf
   Else
      SD3->(DbOrderNickName("XIDPIMSPRO"))
      If !SD3->(DbSeek(xFilial("SD3")+Padr(AllTrim(Str(aJSon[01])),TamSx3("D3_XIDPIMS")[1])))
         SB1->(DbSetOrder(1))
         If !SB1->(DbSeek(xFilial("SB1")+Padr(aJSon[13],TamSx3("B1_COD")[1])))
            _lTdOk := .F.
            _cRetInco := "PRODUTO (SB1) NAO LOCALIZADO"
         Else
            NNR->(DbSetOrder(1))
            If !NNR->(DbSeek(xFilial("NNR")+Padr(aJSon[17],TamSx3("NNR_CODIGO")[1])))
               _lTdOk := .F.
               _cRetInco := "ALMOXARIFADO (NNR) NAO LOCALIZADO"
            Else
               SB2->(DbSetOrder(1))
               If !SB2->(DbSeek(xFilial("SB2")+Padr(aJSon[13],TamSx3("B2_COD")[1])+Padr(aJSon[17],TamSx3("B2_LOCAL")[1])))
                  IncSB9(aJSon[13],aJSon[17],0)
                  SB2->(DbSetOrder(1))
                  If !SB2->(DbSeek(xFilial("SB2")+Padr(aJSon[13],TamSx3("B2_COD")[1])+Padr(aJSon[17],TamSx3("B2_LOCAL")[1])))
                     _lTdOk := .F.
                     _cRetInco := "PRODUTO + ALMOXARIFADO (SB2) NAO LOCALIZADO"
                  EndIf
               Else
                  CTT->(DbSetOrder(1))
                  If !CTT->(DbSeek(xFilial("CTT")+Padr(aJSon[16],TamSx3("CTT_CUSTO")[1])))
                     _lTdOk    := .F.
                     _cRetInco := "CENTRO DE CUSTO (CTT) NAO LOCALIZADO"
                  EndIf
               EndIf
            EndIf
         EndIf
      Else
         _lTdOk    := .F.
         _cRetInco := "JA EXISTE INSERCAO COM ESTE ID"
      EndIf
   EndIf

   If !_lTdOk
      conOut(enter + oemToAnsi("Erro na busca de informcoes! ") + enter)

      ::cRet := "Erro na busca de registro na inclusao "
      ::setResponse('{' + enter) 
      ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
      ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
      ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
      ::setResponse( '"col004n": '+Str(aJSon[04])+',' + enter)
      ::setResponse( '"col005n": '+Str(aJSon[05])+',' + enter)
      ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
      ::setResponse( '"col007d": "'+aJSon[07]+'",' + enter)
      ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
      ::setResponse( '"col009n": '+Str(aJSon[09])+',' + enter)
      ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
      ::setResponse( '"col011c": "'+aJSon[11]+'",' + enter)
      ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
      ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
      ::setResponse( '"col014n": '+Str(aJSon[14])+',' + enter)
      ::setResponse( '"col015c": "'+aJSon[15]+'",' + enter)
      ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
      ::setResponse( '"col017c": "'+aJSon[17]+'",' + enter)
      ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
      ::setResponse( '"col019c": "4",' + enter)
      ::setResponse( '"col020c": "",' + enter)
      ::setResponse( '"col021n": '+Str(aJSon[21])+',' + enter)
      ::setResponse( '"col022c": "'+aJSon[22]+'",' + enter)
      ::setResponse( '"col023c": "'+aJSon[23]+'",' + enter)
      ::setResponse( '"col024c": "'+_cRetInco+'",' + enter)
      ::setResponse( '"col025d": "'+aJSon[25]+'",' + enter)
      ::setResponse( '"col026d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
      ::setResponse( '"col027d": "'+aJSon[27]+'",' + enter)
      ::setResponse( '"col028d": "'+aJSon[28]+'"' + enter)
      ::setResponse('}' + enter)
   Else

      If aJSon[10] == "E"
         nOpcx := 6

         SB1->(DbSetOrder(1))
         SB1->(DbSeek(xFilial("SB1")+Padr(aJSon[13],TamSx3("B1_COD")[1])))

         SB2->(DbSetOrder(1))
         SB2->(DbSeek(xFilial("SB2")+Padr(aJSon[13],TamSx3("B2_COD")[1])+Padr(aJSon[17],TamSx3("B2_LOCAL")[1])))

         _aItem   := {}
         _aOrigem := {}

         _aItem:={{"D3_COD"     ,SB1->B1_COD                ,NIL},;
                  {"D3_UM"      ,SB1->B1_UM                 ,NIL},; 
                  {"D3_QUANT"   ,aJSon[14]                  ,NIL},;
                  {"D3_LOCAL"   ,SB2->B2_LOCAL              ,NIL},;
                  {"D3_ESTORNO" ,"S"                        ,NIL}}
                  //{"D3_CUSTO1"  ,aJSon[21]                  ,NIL},;

         AAdd(_aOrigem,_aItem)
         _aCab1 := {{"D3_DOC"     ,aJSon[13]  , NIL}} 

         //Aadd(aCab,{"CP_SOLICIT" ,aJSon[18]       , Nil })
      Else
         SB1->(DbSetOrder(1))
         SB1->(DbSeek(xFilial("SB1")+Padr(aJSon[13],TamSx3("B1_COD")[1])))

         SB2->(DbSetOrder(1))
         SB2->(DbSeek(xFilial("SB2")+Padr(aJSon[13],TamSx3("B2_COD")[1])+Padr(aJSon[17],TamSx3("B2_LOCAL")[1])))

         dDataBase := CtoD(SubsTr(aJSon[07],1,10))

         _aItem   := {}
         _aOrigem := {}

         _aItem:={{"D3_COD"     ,SB1->B1_COD                ,NIL},;
                  {"D3_UM"      ,SB1->B1_UM                 ,NIL},; 
                  {"D3_QUANT"   ,aJSon[14]                  ,NIL},;
                  {"D3_LOCAL"   ,SB2->B2_LOCAL              ,NIL},;
                  {"D3_CC"      ,aJSon[16]                  ,NIL},;
                  {"D3_OSTEC"   ,AllTrim(Str(aJSon[08]))    ,NIL},;
                  {"D3_XIDPIMS" ,AllTrim(Str(aJSon[01]))    ,NIL},;
                  {"D3_NRBPIMS" ,AllTrim(Str(aJSon[04]))    ,NIL},;
                  {"D3_XORPIMS" ,"032M"                     ,NIL}}
                  //{"D3_CUSTO1"  ,aJSon[21]                  ,NIL},;

         AAdd(_aOrigem,_aItem)
         _aCab1 := {{"D3_TM"     ,GetNewPar("NX_TM032M","501")  , NIL},;
                    {"D3_EMISSAO",dDataBase                      , NIL}} 

         //Aadd(aCab,{"CP_SOLICIT" ,aJSon[18]       , Nil })

      EndIf

      SB1->(DbSetOrder(1))
      SD3->(DbSetOrder(1))
      MSExecAuto({|x,y,z| MATA241(x,y,z)},_aCab1,_aOrigem,nOpcx)

      If !lMsErroAuto
         If nOpcx == 3
            conOut(enter + oemToAnsi("Incluido com sucesso! ") + SD3->D3_DOC + enter)

            ::cRet := "Incluido com sucesso : Codigo: " + SD3->D3_DOC
         Else //Estorno
            conOut(enter + oemToAnsi("Exclusao com sucesso! ") + SubsTr(aJSon[23],1,6) + SubsTr(aJSon[23],7,2) + enter)

            ::cRet := "Exclusao com sucesso : Codigo: " + SubsTr(aJSon[23],1,6) + SubsTr(aJSon[23],7,2)
         EndIf
         
         ::setResponse('{' + enter) 
         ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
         ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
         ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
         ::setResponse( '"col004n": '+Str(aJSon[04])+',' + enter)
         ::setResponse( '"col005n": '+Str(aJSon[05])+',' + enter)
         ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
         ::setResponse( '"col007d": "'+aJSon[07]+'",' + enter)
         ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
         ::setResponse( '"col009n": '+Str(aJSon[09])+',' + enter)
         ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
         ::setResponse( '"col011c": "'+aJSon[11]+'",' + enter)
         ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
         ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
         ::setResponse( '"col014n": '+Str(aJSon[14])+',' + enter)
         ::setResponse( '"col015c": "'+aJSon[15]+'",' + enter)
         ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
         ::setResponse( '"col017c": "'+aJSon[17]+'",' + enter)
         ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
         If nOpcx == 3
            ::setResponse( '"col019c": "2",' + enter)
            ::setResponse( '"col020c": "'+ SD3->D3_DOC + '",' + enter)
         Else
            ::setResponse( '"col019c": "2",' + enter)
            ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
         EndIf
         ::setResponse( '"col021n": '+Str(aJSon[21])+',' + enter)
         ::setResponse( '"col022c": "'+aJSon[22]+'",' + enter)
         ::setResponse( '"col023c": "'+aJSon[23]+'",' + enter)
         If nOpcx == 3
            ::setResponse( '"col024c": "INCLUSAO REALIZADA COM SUCESSO",' + enter)
         Else // Estorno
            ::setResponse( '"col024c": "EXCLUSAO REALIZADA COM SUCESSO. DOC: '+aJSon[23]+'",' + enter)
         EndIf
         ::setResponse( '"col025d": "'+aJSon[25]+'",' + enter)
         ::setResponse( '"col026d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
         ::setResponse( '"col027d": "'+aJSon[27]+'",' + enter)
         ::setResponse( '"col028d": "'+aJSon[28]+'"' + enter)
         ::setResponse('}' + enter)
      Else

         _cRetErr := ""
         conOut(OemToAnsi("032M - (SD3) ERRO EXECAUTO"))
         aErroAuto := GetAutoGRLog()
         For nCount := 1 To Len(aErroAuto)
            cLogErro := StrTran(StrTran(aErroAuto[nCount], "<", ""), "-", "") + " " //+ enter
            ConOut(cLogErro)
            _cRetErr += cLogErro
         Next nCount

         ::cRet := "ERRO: " + _cRetErr + enter
         ::setResponse('{' + enter) 
         ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
         ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
         ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
         ::setResponse( '"col004n": '+Str(aJSon[04])+',' + enter)
         ::setResponse( '"col005n": '+Str(aJSon[05])+',' + enter)
         ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
         ::setResponse( '"col007d": "'+aJSon[07]+'",' + enter)
         ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
         ::setResponse( '"col009n": '+Str(aJSon[09])+',' + enter)
         ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
         ::setResponse( '"col011c": "'+aJSon[11]+'",' + enter)
         ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
         ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
         ::setResponse( '"col014n": '+Str(aJSon[14])+',' + enter)
         ::setResponse( '"col015c": "'+aJSon[15]+'",' + enter)
         ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
         ::setResponse( '"col017c": "'+aJSon[17]+'",' + enter)
         ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
         ::setResponse( '"col019c": "4",' + enter)
         ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
         ::setResponse( '"col021n": '+Str(aJSon[21])+',' + enter)
         ::setResponse( '"col022c": "'+aJSon[22]+'",' + enter)
         ::setResponse( '"col023c": "'+aJSon[23]+'",' + enter)
         ::setResponse( '"col024c": "'+_cRetErr+'",' + enter)
         ::setResponse( '"col025d": "'+aJSon[25]+'",' + enter)
         ::setResponse( '"col026d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
         ::setResponse( '"col027d": "'+aJSon[27]+'",' + enter)
         ::setResponse( '"col028d": "'+aJSon[28]+'"' + enter)
         ::setResponse('}' + enter)
         DisarmTransaction()
         break

      EndIf
   EndIf
EndIf

END TRANSACTION

RpcClearEnv()

Return .t.

/*/{Protheus.doc} PIMS061M
Serviço POST de pagamento de serviços/fornecedores
@author Max Ivan
@since 01/09/19
@version P12
@uso MP12
@type function
/*/
WSRESTFUL INT_PIMS_061M DESCRIPTION "Serviço REST de pagamento de serviços/fornecedores"

//COLOCAR CAMPOS OBRIGATORIOS ABAIXO
WSDATA cRet		AS STRING

WSMETHOD POST DESCRIPTION "POST / Pagamento de serviços/fornecedores" WSSYNTAX ""

END WSRESTFUL

WSMETHOD POST WSRECEIVE RECEIVE WSSERVICE INT_PIMS_061M

Local aJSon         := {}
Local aLog		    := {}
Local cJson         := ::getContent()
Local cUniEmp		:= 	""
Local cFilEmp		:= 	""
Local lInclui       := .T.
Local _lTdOk        := .T.
Local _cRetInco     := ""
Local _cRetJson     := ""

Local aCabec  := {}
Local aItens  := {}
Local aLinha  := {}
Local aItemCC := {}
Local aRatCC  := {}
Local nX      := 0
Local nY      := 0
Local cDoc    := ""
Local lOk     := .T.

Private lMsErroAuto    := .F.
Private lMsErroHelp    := .T.
Private lAutoErrNoFile := .T.

oParseJSON := nil

::setContentType("application/json")
FWJsonDeserialize(DecodeUtf8(cJson), @oParseJSON)

conOut(OemToAnsi("061M json: "+cJson))

If ValType(oParseJSON) == "A" //json com mais de 1 linha
   cUniEmp := oParseJSON[1]:col006c
   cFilEmp := oParseJSON[1]:col007c
Else
   cUniEmp := oParseJSON:col006c
   cFilEmp := oParseJSON:col007c
EndIf

RpcSetEnv(cUniEmp,cFilEmp,"","","EST")
cEmpAnt := cUniEmp
cFilAnt := cFilEmp

BEGIN TRANSACTION  

If ValType(oParseJSON) == "A" //json com mais de 1 linha
   _nIJson   := 1
   _nTamJson := Len(oParseJSON)
   While _nIJson <= _nTamJson
      aJSon := {}

      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL001N,"N")) //Identificador exclusivo (PK da tabela) - Valor sequencial e exclusivo
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL002C,"C")) //Código PIMS da instância
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL003N,"N")) //Código PIMS do processo
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL004D,"C")) //Início do período apurado
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL005D,"C")) //Final do período apurado
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL006C,"C")) //Código ERP da organização/empresa
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL007C,"C")) //Código ERP da filial/centro
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL008N,"N")) //Tipo de processo - 11 = Pagamento de serviços de terceiros; 21 = Adiantamentos
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL009D,"C")) //Data determinada para o pagamento
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL010C,"C")) //Código ERP do item
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL011N,"N")) //Código PIMS do item
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL012N,"N")) //Quantidade do item (material / serviço)
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL013C,"C")) //Código ERP do fornecedor / prestador
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL014N,"N")) //Código PIMS do fornecedor / prestador
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL015N,"N")) //Valor total do item
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL016N,"N")) //Valor dos descontos
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL017N,"N")) //Valor líquido
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL018C,"C")) //Código ERP do centro de custo
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL019C,"C")) //Unidade de medida
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL020C,"C")) //Código IBGE do município
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL021C,"C")) //Indicador PIMS da origem
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL022N,"N")) //Código do contrato
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL023N,"N")) //Código PIMS do evento de prestação de serviços
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL024C,"C")) //Descrição do evento de prestação de serviços
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL025C,"C")) //Informa se o evento é intermunicipal
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL026N,"N")) //Código da operação
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL027C,"C")) //Situação da linha - NI = Não Integrado; PI = Em processamento pelo ERP; IT = Integrado; ES = Estornado pelo PIMS; CA = Cancelado
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL028D,"C")) //Data de envio do PIMS
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL029C,"C")) //Número do lote
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL030C,"C")) //Documento gerado no ERP - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL031D,"C")) //Data da integração no ERP - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL032C,"C")) //Mensagem de Integração - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL033C,"C")) //Código Contrato ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL034C,"C")) //Código do Aprovador ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL035C,"C")) //Código do Favorecido ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL036N,"N")) //Código do favorecido Pims
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL037N,"N")) //Percentual do favorecido
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL038N,"N")) //Valor líquido favorecido
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL039N,"N")) //Valor brutro favorecido
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL040C,"C")) //Unidade federativa do munícipio
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL041N,"N")) //Item documento gerado ERP - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL042C,"C")) //Folha serviço ERP - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL043N,"N")) //Número da linha folha serviço ERP - Alimentado pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL044C,"C")) //Conta contábil de Arrendamento
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL045C,"C")) //Número da parcela
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL046C,"C")) //Tipo de documento ERP de acordo com o tipo de propriedade (Prop/Terc)
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL047D,"C")) //Data e hora da Leitura

      _cRetInco := ""

      SC7->(DbOrderNickName("IDPIMS"))
      If !SC7->(DbSeek(xFilial("SC7")+PadR(AllTrim(Str(aJSon[01])),TamSx3("C7_XIDPIMS")[1])))
         DbSelectArea("SA2")
         SA2->(DbSetOrder(1))
         If SA2->(DbSeek(xFilial("SA2")+aJSon[13]))
            If !Empty(SA2->A2_COND)
               DbSelectArea("SB1")
               SB1->(DbSetOrder(1))
               If SB1->(DbSeek(xFilial("SB1")+Padr(aJSon[10],TamSx3("B1_COD")[1])))
                  CTT->(DbSetOrder(1))
                  If !CTT->(DbSeek(xFilial("CTT")+Padr(aJSon[18],TamSx3("CTT_CUSTO")[1])))
                     //Almoxarifado de Origem ou Destino vazio, ou iguais
                     conOut(OemToAnsi("Centro de Custo nao localizado"))
                     _lTdOk := .F.
                     _cRetInco := "Centro de Custo nao localizado"
                  EndIf
               Else
                  //Almoxarifado de Origem ou Destino vazio, ou iguais
                  conOut(OemToAnsi("Produco nao localizado"))
                  _lTdOk := .F.
                  _cRetInco := "Produto nao localizado"
               EndIf
            Else
               //Fornecedor sem Condicao de Pagamento
               conOut(OemToAnsi("Condicao de Pagamento vazia no Fornecedor"))
               _lTdOk := .F.
               _cRetInco := "Condicao de Pagamento vazia no Fornecedor"
            EndIf
         Else
            //Produto nao localizado
            conOut(OemToAnsi("Fornecedor nao localizado"))
            _lTdOk := .F.
            _cRetInco := "Fornecedor nao localizado"
         EndIf
      Else
         //Produto nao localizado
         conOut(OemToAnsi("Pedido ja inserido. Numero: "+SC7->C7_NUM))
         _lTdOk := .F.
         _cRetInco := "Pedido ja inserido. Numero: "+SC7->C7_NUM
      EndIf

      If Empty(aCabec) .and. _lTdOk
         /*
         DbSelectArea("SC7")
         DbSetOrder(1)
         MsSeek(xFilial("SC7")+"zzzzzz",.T.)
         DbSkip(-1)
         cDoc := SC7->C7_NUM
         */
         cDoc := GetSXENum("SC7","C7_NUM")

         aCabec := {}
         aItens := {}

         If Empty(cDoc)
            cDoc := StrZero(1,Len(SC7->C7_NUM))
         //Else
            //cDoc := Soma1(cDoc)
         EndIf

         SC7->(DbSetOrder(1))
         While SC7->(DbSeek(xFilial('SC7')+cDoc))
            ConfirmSx8()
            //cDoc := GetSXENum("SC7","C7_NUM")
            cDoc := Soma1(SC7->C7_NUM)
         EndDo

         aadd(aCabec,{"C7_NUM"     ,cDoc})
         aadd(aCabec,{"C7_EMISSAO" ,dDataBase})
         aadd(aCabec,{"C7_FORNECE" ,SA2->A2_COD})
         aadd(aCabec,{"C7_LOJA"    ,SA2->A2_LOJA})
         aadd(aCabec,{"C7_COND"    ,SA2->A2_COND})
         aadd(aCabec,{"C7_CONTATO" ,"PIMS"})
         aadd(aCabec,{"C7_FILENT"  ,cFilAnt})
      EndIf

      If _nIJson == 1
         ::cRet := "Processo em Lote "
         _cRetJson := _cRetJson + '[' + enter
      EndIf
      If !_lTdOk
         conOut(enter + oemToAnsi("Erro na busca de informacoes! ") + enter)

         _cRetJson := _cRetJson + '{' + enter
         _cRetJson := _cRetJson + '"col001n": '+Str(aJSon[01])+',' + enter
         _cRetJson := _cRetJson + '"col002c": "'+aJSon[02]+'",' + enter
         _cRetJson := _cRetJson + '"col003n": '+Str(aJSon[03])+',' + enter
         _cRetJson := _cRetJson + '"col004d": "'+aJSon[04]+'",' + enter
         _cRetJson := _cRetJson + '"col005d": "'+aJSon[05]+'",' + enter
         _cRetJson := _cRetJson + '"col006c": "'+aJSon[06]+'",' + enter
         _cRetJson := _cRetJson + '"col007c": "'+aJSon[07]+'",' + enter
         _cRetJson := _cRetJson + '"col008n": '+Str(aJSon[08])+',' + enter
         _cRetJson := _cRetJson + '"col009d": "'+aJSon[09]+'",' + enter
         _cRetJson := _cRetJson + '"col010c": "'+aJSon[10]+'",' + enter
         _cRetJson := _cRetJson + '"col011n": '+Str(aJSon[11])+',' + enter
         _cRetJson := _cRetJson + '"col012n": '+Str(aJSon[12])+',' + enter
         _cRetJson := _cRetJson + '"col013c": "'+aJSon[13]+'",' + enter
         _cRetJson := _cRetJson + '"col014n": '+Str(aJSon[14])+',' + enter
         _cRetJson := _cRetJson + '"col015n": '+Str(aJSon[15])+',' + enter
         _cRetJson := _cRetJson + '"col016n": '+Str(aJSon[16])+',' + enter
         _cRetJson := _cRetJson + '"col017n": '+Str(aJSon[17])+',' + enter
         _cRetJson := _cRetJson + '"col018c": "'+aJSon[18]+'",' + enter
         _cRetJson := _cRetJson + '"col019c": "'+aJSon[19]+'",' + enter
         _cRetJson := _cRetJson + '"col020c": "'+aJSon[20]+'",' + enter
         _cRetJson := _cRetJson + '"col021c": "'+aJSon[21]+'",' + enter
         _cRetJson := _cRetJson + '"col022n": '+Str(aJSon[22])+',' + enter
         _cRetJson := _cRetJson + '"col023n": '+Str(aJSon[23])+',' + enter
         _cRetJson := _cRetJson + '"col024c": "'+aJSon[24]+'",' + enter
         _cRetJson := _cRetJson + '"col025c": "'+aJSon[25]+'",' + enter
         _cRetJson := _cRetJson + '"col026n": '+Str(aJSon[26])+',' + enter
         _cRetJson := _cRetJson + '"col027c": "NI",' + enter
         _cRetJson := _cRetJson + '"col028d": "'+aJSon[28]+'",' + enter
         _cRetJson := _cRetJson + '"col029c": "'+aJSon[29]+'",' + enter
         _cRetJson := _cRetJson + '"col030c": "'+cDoc+'",' + enter
         _cRetJson := _cRetJson + '"col031d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter
         _cRetJson := _cRetJson + '"col032c": "'+_cRetInco+'",' + enter
         _cRetJson := _cRetJson + '"col033c": "'+aJSon[33]+'",' + enter
         _cRetJson := _cRetJson + '"col034c": "'+aJSon[34]+'",' + enter
         _cRetJson := _cRetJson + '"col035c": "'+aJSon[35]+'",' + enter
         _cRetJson := _cRetJson + '"col036n": '+Str(aJSon[36])+',' + enter
         _cRetJson := _cRetJson + '"col037n": '+Str(aJSon[37])+',' + enter
         _cRetJson := _cRetJson + '"col038n": '+Str(aJSon[38])+',' + enter
         _cRetJson := _cRetJson + '"col039n": '+Str(aJSon[39])+',' + enter
         _cRetJson := _cRetJson + '"col040c": "'+aJSon[40]+'",' + enter
         _cRetJson := _cRetJson + '"col041n": '+Str(aJSon[41])+',' + enter
         _cRetJson := _cRetJson + '"col042c": "'+aJSon[42]+'",' + enter
         _cRetJson := _cRetJson + '"col043n": '+Str(aJSon[43])+',' + enter
         _cRetJson := _cRetJson + '"col044c": "'+aJSon[44]+'",' + enter
         _cRetJson := _cRetJson + '"col045c": "'+aJSon[45]+'",' + enter
         _cRetJson := _cRetJson + '"col046c": "'+aJSon[46]+'",' + enter
         _cRetJson := _cRetJson + '"col047d": "'+aJSon[47]+'"' + enter

         If _nIJson == _nTamJson
            _cRetJson := _cRetJson + '}' + enter
         Else
            _cRetJson := _cRetJson + '},' + enter
         EndIf
      Else
         _cRetJson := _cRetJson + '{' + enter
         _cRetJson := _cRetJson + '"col001n": '+Str(aJSon[01])+',' + enter
         _cRetJson := _cRetJson + '"col002c": "'+aJSon[02]+'",' + enter
         _cRetJson := _cRetJson + '"col003n": '+Str(aJSon[03])+',' + enter
         _cRetJson := _cRetJson + '"col004d": "'+aJSon[04]+'",' + enter
         _cRetJson := _cRetJson + '"col005d": "'+aJSon[05]+'",' + enter
         _cRetJson := _cRetJson + '"col006c": "'+aJSon[06]+'",' + enter
         _cRetJson := _cRetJson + '"col007c": "'+aJSon[07]+'",' + enter
         _cRetJson := _cRetJson + '"col008n": '+Str(aJSon[08])+',' + enter
         _cRetJson := _cRetJson + '"col009d": "'+aJSon[09]+'",' + enter
         _cRetJson := _cRetJson + '"col010c": "'+aJSon[10]+'",' + enter
         _cRetJson := _cRetJson + '"col011n": '+Str(aJSon[11])+',' + enter
         _cRetJson := _cRetJson + '"col012n": '+Str(aJSon[12])+',' + enter
         _cRetJson := _cRetJson + '"col013c": "'+aJSon[13]+'",' + enter
         _cRetJson := _cRetJson + '"col014n": '+Str(aJSon[14])+',' + enter
         _cRetJson := _cRetJson + '"col015n": '+Str(aJSon[15])+',' + enter
         _cRetJson := _cRetJson + '"col016n": '+Str(aJSon[16])+',' + enter
         _cRetJson := _cRetJson + '"col017n": '+Str(aJSon[17])+',' + enter
         _cRetJson := _cRetJson + '"col018c": "'+aJSon[18]+'",' + enter
         _cRetJson := _cRetJson + '"col019c": "'+aJSon[19]+'",' + enter
         _cRetJson := _cRetJson + '"col020c": "'+aJSon[20]+'",' + enter
         _cRetJson := _cRetJson + '"col021c": "'+aJSon[21]+'",' + enter
         _cRetJson := _cRetJson + '"col022n": '+Str(aJSon[22])+',' + enter
         _cRetJson := _cRetJson + '"col023n": '+Str(aJSon[23])+',' + enter
         _cRetJson := _cRetJson + '"col024c": "'+aJSon[24]+'",' + enter
         _cRetJson := _cRetJson + '"col025c": "'+aJSon[25]+'",' + enter
         _cRetJson := _cRetJson + '"col026n": '+Str(aJSon[26])+',' + enter
         _cRetJson := _cRetJson + '"col027c": "IT",' + enter
         _cRetJson := _cRetJson + '"col028d": "'+aJSon[28]+'",' + enter
         _cRetJson := _cRetJson + '"col029c": "'+aJSon[29]+'",' + enter
         _cRetJson := _cRetJson + '"col030c": "'+cDoc+'",' + enter
         _cRetJson := _cRetJson + '"col031d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter
         _cRetJson := _cRetJson + '"col032c": "'+aJSon[32]+'",' + enter
         _cRetJson := _cRetJson + '"col033c": "'+aJSon[33]+'",' + enter
         _cRetJson := _cRetJson + '"col034c": "'+aJSon[34]+'",' + enter
         _cRetJson := _cRetJson + '"col035c": "'+aJSon[35]+'",' + enter
         _cRetJson := _cRetJson + '"col036n": '+Str(aJSon[36])+',' + enter
         _cRetJson := _cRetJson + '"col037n": '+Str(aJSon[37])+',' + enter
         _cRetJson := _cRetJson + '"col038n": '+Str(aJSon[38])+',' + enter
         _cRetJson := _cRetJson + '"col039n": '+Str(aJSon[39])+',' + enter
         _cRetJson := _cRetJson + '"col040c": "'+aJSon[40]+'",' + enter
         _cRetJson := _cRetJson + '"col041n": '+Str(aJSon[41])+',' + enter
         _cRetJson := _cRetJson + '"col042c": "'+aJSon[42]+'",' + enter
         _cRetJson := _cRetJson + '"col043n": '+Str(aJSon[43])+',' + enter
         _cRetJson := _cRetJson + '"col044c": "'+aJSon[44]+'",' + enter
         _cRetJson := _cRetJson + '"col045c": "'+aJSon[45]+'",' + enter
         _cRetJson := _cRetJson + '"col046c": "'+aJSon[46]+'",' + enter
         _cRetJson := _cRetJson + '"col047d": "'+aJSon[47]+'"' + enter

         If _nIJson == _nTamJson
            _cRetJson := _cRetJson + '}' + enter
         Else
            _cRetJson := _cRetJson + '},' + enter
         EndIf

         aLinha := {}
         aadd(aLinha,{"C7_PRODUTO" ,SB1->B1_COD,Nil})
         aadd(aLinha,{"C7_QUANT"   ,1          ,Nil})
         aadd(aLinha,{"C7_PRECO"   ,aJSon[17]  ,Nil})
         aadd(aLinha,{"C7_TOTAL"   ,aJSon[17]  ,Nil})
         aadd(aLinha,{"C7_CC"      ,aJSon[18]  ,Nil})
         //aadd(aLinha,{"C7_TES"     ,SB1->B1_TE ,Nil})
         aadd(aLinha,{"C7_XCODAPL" ,"03"       ,Nil})
         aadd(aLinha,{"C7_DATPRF"  ,CtoD(SubsTr(aJSon[09],1,10)),Nil})
         //aadd(aLinha,{"C7_USER"    ,"000113"   ,Nil})
         aadd(aLinha,{"C7_APROV"   ,"000006"   ,Nil})
         //aadd(aLinha,{"C7_GRUPCOM" ,""       ,Nil})
         aadd(aLinha,{"C7_XIDPIMS" ,AllTrim(Str(aJSon[01])),Nil})
         aadd(aItens,aLinha)

      EndIf
      If _nIJson == _nTamJson
         _cRetJson := _cRetJson + ']' + enter
      EndIf
      _nIJson++
   EndDo

   If !Empty(aCabec) .and. !Empty(aItens)
      MSExecAuto({|v,x,y,z| MATA120(v,x,y,z)},1,aCabec,aItens,3)
      //MATA120(1,aCabec,aItens,3,,aRatCC)

      If !lMsErroAuto
         ::setResponse(_cRetJson)
      Else

         conOut(OemToAnsi("Erro na inclusao"))
         //aLog := getAutoGRLog()
         aLog := MostraErro()
         ::cRet := "ERRO" + enter
         //for i := 1 to len(aLog)
         ::cRet += aLog + enter
         //next i
         conout(enter + ::cRet + enter)
         /*
         ::setResponse('{') 
         ::setResponse( '"Retorno apos execucao": "' + ::cRet + '"')
         ::setResponse('}')
         */

         _cRetJson := '{' + enter
         _cRetJson := _cRetJson + '"col001n": '+Str(aJSon[01])+',' + enter
         _cRetJson := _cRetJson + '"col002c": "'+aJSon[02]+'",' + enter
         _cRetJson := _cRetJson + '"col003n": '+Str(aJSon[03])+',' + enter
         _cRetJson := _cRetJson + '"col004d": "'+aJSon[04]+'",' + enter
         _cRetJson := _cRetJson + '"col005d": "'+aJSon[05]+'",' + enter
         _cRetJson := _cRetJson + '"col006c": "'+aJSon[06]+'",' + enter
         _cRetJson := _cRetJson + '"col007c": "'+aJSon[07]+'",' + enter
         _cRetJson := _cRetJson + '"col008n": '+Str(aJSon[08])+',' + enter
         _cRetJson := _cRetJson + '"col009d": "'+aJSon[09]+'",' + enter
         _cRetJson := _cRetJson + '"col010c": "'+aJSon[10]+'",' + enter
         _cRetJson := _cRetJson + '"col011n": '+Str(aJSon[11])+',' + enter
         _cRetJson := _cRetJson + '"col012n": '+Str(aJSon[12])+',' + enter
         _cRetJson := _cRetJson + '"col013c": "'+aJSon[13]+'",' + enter
         _cRetJson := _cRetJson + '"col014n": '+Str(aJSon[14])+',' + enter
         _cRetJson := _cRetJson + '"col015n": '+Str(aJSon[15])+',' + enter
         _cRetJson := _cRetJson + '"col016n": '+Str(aJSon[16])+',' + enter
         _cRetJson := _cRetJson + '"col017n": '+Str(aJSon[17])+',' + enter
         _cRetJson := _cRetJson + '"col018c": "'+aJSon[18]+'",' + enter
         _cRetJson := _cRetJson + '"col019c": "'+aJSon[19]+'",' + enter
         _cRetJson := _cRetJson + '"col020c": "'+aJSon[20]+'",' + enter
         _cRetJson := _cRetJson + '"col021c": "'+aJSon[21]+'",' + enter
         _cRetJson := _cRetJson + '"col022n": '+Str(aJSon[22])+',' + enter
         _cRetJson := _cRetJson + '"col023n": '+Str(aJSon[23])+',' + enter
         _cRetJson := _cRetJson + '"col024c": "'+aJSon[24]+'",' + enter
         _cRetJson := _cRetJson + '"col025c": "'+aJSon[25]+'",' + enter
         _cRetJson := _cRetJson + '"col026n": '+Str(aJSon[26])+',' + enter
         _cRetJson := _cRetJson + '"col027c": "NI",' + enter
         _cRetJson := _cRetJson + '"col028d": "'+aJSon[28]+'",' + enter
         _cRetJson := _cRetJson + '"col029c": "'+aJSon[29]+'",' + enter
         _cRetJson := _cRetJson + '"col030c": "'+cDoc+'",' + enter
         _cRetJson := _cRetJson + '"col031d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter
         _cRetJson := _cRetJson + '"col032c": "'+::cRet+'",' + enter
         _cRetJson := _cRetJson + '"col033c": "'+aJSon[33]+'",' + enter
         _cRetJson := _cRetJson + '"col034c": "'+aJSon[34]+'",' + enter
         _cRetJson := _cRetJson + '"col035c": "'+aJSon[35]+'",' + enter
         _cRetJson := _cRetJson + '"col036n": '+Str(aJSon[36])+',' + enter
         _cRetJson := _cRetJson + '"col037n": '+Str(aJSon[37])+',' + enter
         _cRetJson := _cRetJson + '"col038n": '+Str(aJSon[38])+',' + enter
         _cRetJson := _cRetJson + '"col039n": '+Str(aJSon[39])+',' + enter
         _cRetJson := _cRetJson + '"col040c": "'+aJSon[40]+'",' + enter
         _cRetJson := _cRetJson + '"col041n": '+Str(aJSon[41])+',' + enter
         _cRetJson := _cRetJson + '"col042c": "'+aJSon[42]+'",' + enter
         _cRetJson := _cRetJson + '"col043n": '+Str(aJSon[43])+',' + enter
         _cRetJson := _cRetJson + '"col044c": "'+aJSon[44]+'",' + enter
         _cRetJson := _cRetJson + '"col045c": "'+aJSon[45]+'",' + enter
         _cRetJson := _cRetJson + '"col046c": "'+aJSon[46]+'",' + enter
         _cRetJson := _cRetJson + '"col047d": "'+aJSon[47]+'"' + enter
         _cRetJson := _cRetJson + '}' + enter
         ::setResponse(_cRetJson)

         lInclui := .F.
         DisarmTransaction()
         break
      EndIf
   Else
      ::cRet := "ERRO" + enter
      conout(enter + ::cRet + enter)
      ::setResponse(_cRetJson)
   EndIf
Else
   AAdd(aJSon,ValInfo(oParseJSON:COL001N,"N")) //Identificador exclusivo (PK da tabela) - Valor sequencial e exclusivo
   AAdd(aJSon,ValInfo(oParseJSON:COL002C,"C")) //Código PIMS da instância
   AAdd(aJSon,ValInfo(oParseJSON:COL003N,"N")) //Código PIMS do processo
   AAdd(aJSon,ValInfo(oParseJSON:COL004D,"C")) //Início do período apurado
   AAdd(aJSon,ValInfo(oParseJSON:COL005D,"C")) //Final do período apurado
   AAdd(aJSon,ValInfo(oParseJSON:COL006C,"C")) //Código ERP da organização/empresa
   AAdd(aJSon,ValInfo(oParseJSON:COL007C,"C")) //Código ERP da filial/centro
   AAdd(aJSon,ValInfo(oParseJSON:COL008N,"N")) //Tipo de processo - 11 = Pagamento de serviços de terceiros; 21 = Adiantamentos
   AAdd(aJSon,ValInfo(oParseJSON:COL009D,"C")) //Data determinada para o pagamento
   AAdd(aJSon,ValInfo(oParseJSON:COL010C,"C")) //Código ERP do item
   AAdd(aJSon,ValInfo(oParseJSON:COL011N,"N")) //Código PIMS do item
   AAdd(aJSon,ValInfo(oParseJSON:COL012N,"N")) //Quantidade do item (material / serviço)
   AAdd(aJSon,ValInfo(oParseJSON:COL013C,"C")) //Código ERP do fornecedor / prestador
   AAdd(aJSon,ValInfo(oParseJSON:COL014N,"N")) //Código PIMS do fornecedor / prestador
   AAdd(aJSon,ValInfo(oParseJSON:COL015N,"N")) //Valor total do item
   AAdd(aJSon,ValInfo(oParseJSON:COL016N,"N")) //Valor dos descontos
   AAdd(aJSon,ValInfo(oParseJSON:COL017N,"N")) //Valor líquido
   AAdd(aJSon,ValInfo(oParseJSON:COL018C,"C")) //Código ERP do centro de custo
   AAdd(aJSon,ValInfo(oParseJSON:COL019C,"C")) //Unidade de medida
   AAdd(aJSon,ValInfo(oParseJSON:COL020C,"C")) //Código IBGE do município
   AAdd(aJSon,ValInfo(oParseJSON:COL021C,"C")) //Indicador PIMS da origem
   AAdd(aJSon,ValInfo(oParseJSON:COL022N,"N")) //Código do contrato
   AAdd(aJSon,ValInfo(oParseJSON:COL023N,"N")) //Código PIMS do evento de prestação de serviços
   AAdd(aJSon,ValInfo(oParseJSON:COL024C,"C")) //Descrição do evento de prestação de serviços
   AAdd(aJSon,ValInfo(oParseJSON:COL025C,"C")) //Informa se o evento é intermunicipal
   AAdd(aJSon,ValInfo(oParseJSON:COL026N,"N")) //Código da operação
   AAdd(aJSon,ValInfo(oParseJSON:COL027C,"C")) //Situação da linha - NI = Não Integrado; PI = Em processamento pelo ERP; IT = Integrado; ES = Estornado pelo PIMS; CA = Cancelado
   AAdd(aJSon,ValInfo(oParseJSON:COL028D,"C")) //Data de envio do PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL029C,"C")) //Número do lote
   AAdd(aJSon,ValInfo(oParseJSON:COL030C,"C")) //Documento gerado no ERP - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL031D,"C")) //Data da integração no ERP - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL032C,"C")) //Mensagem de Integração - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL033C,"C")) //Código Contrato ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL034C,"C")) //Código do Aprovador ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL035C,"C")) //Código do Favorecido ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL036N,"N")) //Código do favorecido Pims
   AAdd(aJSon,ValInfo(oParseJSON:COL037N,"N")) //Percentual do favorecido
   AAdd(aJSon,ValInfo(oParseJSON:COL038N,"N")) //Valor líquido favorecido
   AAdd(aJSon,ValInfo(oParseJSON:COL039N,"N")) //Valor brutro favorecido
   AAdd(aJSon,ValInfo(oParseJSON:COL040C,"C")) //Unidade federativa do munícipio
   AAdd(aJSon,ValInfo(oParseJSON:COL041N,"N")) //Item documento gerado ERP - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL042C,"C")) //Folha serviço ERP - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL043N,"N")) //Número da linha folha serviço ERP - Alimentado pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL044C,"C")) //Conta contábil de Arrendamento
   AAdd(aJSon,ValInfo(oParseJSON:COL045C,"C")) //Número da parcela
   AAdd(aJSon,ValInfo(oParseJSON:COL046C,"C")) //Tipo de documento ERP de acordo com o tipo de propriedade (Prop/Terc)
   AAdd(aJSon,ValInfo(oParseJSON:COL047D,"C")) //Data e hora da Leitura

   _lTdOK   := .T.
   _cRetErr := ""
   _cNumReg := ""

   SA2->(DbSetOrder(1))
   If SA2->(DbSeek(xFilial("SA2")+Padr(AllTrim(aJSon[13]),TamSx3("A2_COD")[1]+TamSx3("A2_LOJA")[1])))
      SB1->(DbSetOrder(1))
      If SB1->(DbSeek(xFilial("SB1")+Padr(aJSon[10],TamSx3("B1_COD")[1])))
         CTT->(DbSetOrder(1))
         If CTT->(DbSeek(xFilial("CTT")+Padr(aJSon[18],TamSx3("CTT_CUSTO")[1])))
            If Alltrim(aJSon[46]) == "PEDIDO_COMPRA"
               SC7->(DbOrderNickName("IDPIMS"))
               If SC7->(DbSeek(xFilial("SC7")+PadR(AllTrim(Str(aJSon[01])),TamSx3("C7_XIDPIMS")[1])))
                  _lTdOK   := .F.
                  _cRetErr := "JA EXISTE PEDIDO DE COMPRAS: "+SC7->C7_NUM+" COM ID: "+AllTrim(Str(aJSon[01]))
                  conOut(OemToAnsi("JA EXISTE PEDIDO DE COMPRAS: "+SC7->C7_NUM+" COM ID: "+AllTrim(Str(aJSon[01]))))
               EndIf
            ElseIf Alltrim(aJSon[46]) == "TITULO_PAGAR"
               SE2->(DbOrderNickName("E2ORIDPIMS"))
               If SE2->(DbSeek(xFilial("SE2")+"061M"+PadR(AllTrim(Str(aJSon[01])),TamSx3("E2_XIDPIMS")[1])))
                  _lTdOK   := .F.
                  _cRetErr := "JA EXISTE TITULO: "+SE2->E2_NUM+" COM ID: "+AllTrim(Str(aJSon[01]))
                  conOut(OemToAnsi("JA EXISTE TITULO: "+SE2->E2_NUM+" COM ID: "+AllTrim(Str(aJSon[01]))))
               EndIf
            Else
               _lTdOK   := .F.
               _cRetErr := "COL046C diferente de TITULO_PAGAR e PEDIDO_COMPRA"
               conOut(OemToAnsi("061M: COL046C diferente de PEDIDO_COMPRA e TITULO_PAGAR"))
            EndIf
         Else
            _lTdOK   := .F.
            _cRetErr := "CENTRO DE CUSTO (COL018C) NAO LOCALIZADO"
            conOut(OemToAnsi("061M: Centro de Custo nao localizado"))
         EndIf
      Else
         _lTdOK   := .F.
         _cRetErr := "PRODUTO (COL010C) NAO LOCALIZADO"
         conOut(OemToAnsi("061M: Produco nao localizado"))
      EndIf
   Else
      _lTdOK   := .F.
      _cRetErr := "FORNECEDOR (COL013C) NAO LOCALIZADO"
      conOut(OemToAnsi("061M: Fornecedor nao localizado"))
   EndIf

   If _lTdOK
      If Alltrim(aJSon[46]) == "PEDIDO_COMPRA"
         /*
         DbSelectArea("SC7")
         DbSetOrder(1)
         MsSeek(xFilial("SC7")+"zzzzzz",.T.)
         DbSkip(-1)
         cDoc := SC7->C7_NUM
         */
         cDoc := GetSXENum("SC7","C7_NUM")

         aCabec := {}
         aItens := {}

         If Empty(cDoc)
            cDoc := StrZero(1,Len(SC7->C7_NUM))
         //Else
            //cDoc := Soma1(cDoc)
         EndIf

         SC7->(DbSetOrder(1))
         While SC7->(DbSeek(xFilial('SC7')+cDoc))
            ConfirmSx8()
            //cDoc := GetSXENum("SC7","C7_NUM")
            cDoc := Soma1(SC7->C7_NUM)
         EndDo

         aadd(aCabec,{"C7_NUM"     ,cDoc})
         aadd(aCabec,{"C7_EMISSAO" ,dDataBase})
         aadd(aCabec,{"C7_FORNECE" ,SA2->A2_COD})
         aadd(aCabec,{"C7_LOJA"    ,SA2->A2_LOJA})
         aadd(aCabec,{"C7_COND"    ,If(Empty(SA2->A2_COND),"001",SA2->A2_COND)})
         aadd(aCabec,{"C7_CONTATO" ,"PIMS"})
         aadd(aCabec,{"C7_FILENT"  ,cFilAnt})

         aLinha := {}
         aadd(aLinha,{"C7_PRODUTO" ,SB1->B1_COD,Nil})
         aadd(aLinha,{"C7_QUANT"   ,1          ,Nil})
         aadd(aLinha,{"C7_PRECO"   ,aJSon[17]  ,Nil})
         aadd(aLinha,{"C7_TOTAL"   ,aJSon[17]  ,Nil})
         aadd(aLinha,{"C7_CC"      ,aJSon[18]  ,Nil})
         //aadd(aLinha,{"C7_TES"     ,SB1->B1_TE ,Nil})
         //aadd(aLinha,{"C7_XCODAPL" ,"03"       ,Nil})
         aadd(aLinha,{"C7_DATPRF"  ,CtoD(SubsTr(aJSon[09],1,10)),Nil})
         //aadd(aLinha,{"C7_USER"    ,"000113"   ,Nil})
         aadd(aLinha,{"C7_APROV"   ,"000003"   ,Nil})
         //aadd(aLinha,{"C7_GRUPCOM" ,""       ,Nil})
         aadd(aLinha,{"C7_XIDPIMS" ,AllTrim(Str(aJSon[01])),Nil})
         aadd(aItens,aLinha)

         MSExecAuto({|v,x,y,z| MATA120(v,x,y,z)},1,aCabec,aItens,3)
         //MATA120(1,aCabec,aItens,3,,aRatCC)

         If lMsErroAuto 
            conOut(OemToAnsi("Erro na inclusao"))
            //aLog := getAutoGRLog()
            aLog := getAutoGRLog() //MostraErro()

            _cErro := ""
            If ValType(aLog) == "A" //If Len(aLog) > 0
               For nX := 1 to Len(aLog)
                  _cErro := _cErro+aLog[nX]+" "+CRLF
                  conout(enter + aLog[nX] + enter)
               Next
            Else
               _cErro := _cErro+aLog+" "+CRLF
               conout(enter + aLog + enter)
            EndIf
            ::cRet := "ERRO" + enter
            //for i := 1 to len(aLog)
            ::cRet += _cErro + enter
            //next i
            conout(enter + ::cRet + enter)

            /*
            ::setResponse('{') 
            ::setResponse( '"Retorno apos execucao": "' + ::cRet + '"')
            ::setResponse('}')
            */

            conOut(enter + oemToAnsi("ERRO NA INCLUSAO") + enter)
            ::cRet := "ERRO NA INCLUSAO"
            ::setResponse('{' + enter) 
            ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
            ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
            ::setResponse( '"col003n": '+Str(aJSon[03])+',' + enter)
            ::setResponse( '"col004d": "'+aJSon[04]+'",' + enter)
            ::setResponse( '"col005d": "'+aJSon[05]+'",' + enter)
            ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
            ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
            ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
            ::setResponse( '"col009d": "'+aJSon[09]+'",' + enter)
            ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
            ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
            ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
            ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
            ::setResponse( '"col014n": '+Str(aJSon[14])+',' + enter)
            ::setResponse( '"col015n": '+Str(aJSon[15])+',' + enter)
            ::setResponse( '"col016n": '+Str(aJSon[16])+',' + enter)
            ::setResponse( '"col017n": '+Str(aJSon[17])+',' + enter)
            ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
            ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
            ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
            ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
            ::setResponse( '"col022n": '+Str(aJSon[22])+',' + enter)
            ::setResponse( '"col023n": '+Str(aJSon[23])+',' + enter)
            ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
            ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
            ::setResponse( '"col026n": '+Str(aJSon[26])+',' + enter)
            ::setResponse( '"col027c": "ER",' + enter)
            ::setResponse( '"col028d": "'+aJSon[28]+'",' + enter)
            ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
            ::setResponse( '"col030c": "'+aJSon[30]+'",' + enter)
            ::setResponse( '"col031d": "'+aJSon[31]+'",' + enter)
            ::setResponse( '"col032c": "'+_cErro+'",' + enter)
            ::setResponse( '"col033c": "'+aJSon[33]+'",' + enter)
            ::setResponse( '"col034c": "'+aJSon[34]+'",' + enter)
            ::setResponse( '"col035c": "'+aJSon[35]+'",' + enter)
            ::setResponse( '"col036n": '+Str(aJSon[36])+',' + enter)
            ::setResponse( '"col037n": '+Str(aJSon[37])+',' + enter)
            ::setResponse( '"col038n": '+Str(aJSon[38])+',' + enter)
            ::setResponse( '"col039n": '+Str(aJSon[39])+',' + enter)
            ::setResponse( '"col040c": "'+aJSon[40]+'",' + enter)
            ::setResponse( '"col041n": '+Str(aJSon[41])+',' + enter)
            ::setResponse( '"col042c": "'+aJSon[42]+'",' + enter)
            ::setResponse( '"col043n": '+Str(aJSon[43])+',' + enter)
            ::setResponse( '"col044c": "'+aJSon[44]+'",' + enter)
            ::setResponse( '"col045c": "'+aJSon[45]+'",' + enter)
            ::setResponse( '"col046c": "'+aJSon[46]+'",' + enter)
            ::setResponse( '"col047d": "'+aJSon[47]+'"' + enter)
            ::setResponse('}' + enter)

            lInclui := .F.
            DisarmTransaction()
            break
         Else
            conOut(enter + oemToAnsi("Incluido com sucesso! ") + cDoc + enter)
            ::cRet := "Incluido com sucesso : Codigo: " + cDoc
            ::setResponse('{' + enter) 
            ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
            ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
            ::setResponse( '"col003n": '+Str(aJSon[03])+',' + enter)
            ::setResponse( '"col004d": "'+aJSon[04]+'",' + enter)
            ::setResponse( '"col005d": "'+aJSon[05]+'",' + enter)
            ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
            ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
            ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
            ::setResponse( '"col009d": "'+aJSon[09]+'",' + enter)
            ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
            ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
            ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
            ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
            ::setResponse( '"col014n": '+Str(aJSon[14])+',' + enter)
            ::setResponse( '"col015n": '+Str(aJSon[15])+',' + enter)
            ::setResponse( '"col016n": '+Str(aJSon[16])+',' + enter)
            ::setResponse( '"col017n": '+Str(aJSon[17])+',' + enter)
            ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
            ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
            ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
            ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
            ::setResponse( '"col022n": '+Str(aJSon[22])+',' + enter)
            ::setResponse( '"col023n": '+Str(aJSon[23])+',' + enter)
            ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
            ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
            ::setResponse( '"col026n": '+Str(aJSon[26])+',' + enter)
            ::setResponse( '"col027c": "IT",' + enter)
            ::setResponse( '"col028d": "'+aJSon[28]+'",' + enter)
            ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
            ::setResponse( '"col030c": "'+cDoc+'",' + enter)
            ::setResponse( '"col031d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
            ::setResponse( '"col032c": "'+aJSon[32]+'",' + enter)
            ::setResponse( '"col033c": "'+aJSon[33]+'",' + enter)
            ::setResponse( '"col034c": "'+aJSon[34]+'",' + enter)
            ::setResponse( '"col035c": "'+aJSon[35]+'",' + enter)
            ::setResponse( '"col036n": '+Str(aJSon[36])+',' + enter)
            ::setResponse( '"col037n": '+Str(aJSon[37])+',' + enter)
            ::setResponse( '"col038n": '+Str(aJSon[38])+',' + enter)
            ::setResponse( '"col039n": '+Str(aJSon[39])+',' + enter)
            ::setResponse( '"col040c": "'+aJSon[40]+'",' + enter)
            ::setResponse( '"col041n": '+Str(aJSon[41])+',' + enter)
            ::setResponse( '"col042c": "'+aJSon[42]+'",' + enter)
            ::setResponse( '"col043n": '+Str(aJSon[43])+',' + enter)
            ::setResponse( '"col044c": "'+aJSon[44]+'",' + enter)
            ::setResponse( '"col045c": "'+aJSon[45]+'",' + enter)
            ::setResponse( '"col046c": "'+aJSon[46]+'",' + enter)
            ::setResponse( '"col047d": "'+aJSon[47]+'"' + enter)
            ::setResponse('}' + enter)
         EndIf
      ElseIf Alltrim(aJSon[46]) == "TITULO_PAGAR"
         conOut(OemToAnsi("entrou em TITULO_PAGAR"))
         SF1->(DbOrderNickName("XORIDPIMS"))
         If SF1->(DbSeek(xFilial("SF1")+"071M"+Padr(AllTrim(Str(oParseJSON:col063n)),TamSx3("F1_XIDPIMS")[1])))
            conOut(OemToAnsi("encontrou o item na SF1"))
            _aDeducoes := oParseJSON:deducoes
            _nDeducoes := 1
            conOut(OemToAnsi("antes do While das deduções"))
            While _nDeducoes <= Len(_aDeducoes)
               conOut(OemToAnsi("processando item "+AllTrim(Str(_nDeducoes))+" das deduções."))
               conOut(OemToAnsi("Info pos 01 "+AllTrim(Str(_aDeducoes[_nDeducoes]:col001n))))
               conOut(OemToAnsi("Info pos 11 "+AllTrim(Str(_aDeducoes[_nDeducoes]:col011n))))
               //conOut(OemToAnsi("numero de iten "+AllTrim(Str(Len(_aDeducoes[_nDeducoes])))))
               SE2->(DbSetOrder(1))
               If SE2->(DbSeek(SF1->F1_FILIAL+SF1->F1_PREFIXO+SF1->F1_DUPL))
                  conOut(OemToAnsi("antes de montar o aVetor do AB- do item "+AllTrim(Str(_nDeducoes))+" das deduções."))
                  conOut(OemToAnsi("E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO: "+SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_PARCELA+SE2->E2_TIPO))
                  //conOut(OemToAnsi("_aDeducoes[_nDeducoes,11]: "+_aDeducoes[_nDeducoes,11]))
                  //conOut(OemToAnsi("_aDeducoes[_nDeducoes,09]: "+_aDeducoes[_nDeducoes,09]))
                  //conOut(OemToAnsi("AllTrim(Str(aJSon[01])): "+AllTrim(Str(aJSon[01]))))
                  aVetor := {{"E2_TIPO"	 ,"AB-"                                          ,Nil},;
                             {"E2_VALOR"   ,_aDeducoes[_nDeducoes]:col011n                 ,Nil},;
                             {"E2_HIST"	 ,_aDeducoes[_nDeducoes]:col009c                 ,Nil},;
                             {"E2_XORPIMS" ,"061M"                                         ,Nil},;
                             {"E2_XIDPIMS" ,AllTrim(Str(_aDeducoes[_nDeducoes]:col001n))   ,Nil}}

                  MSExecAuto({|x,y| Fina050(x,y)},aVetor,3) //Inclusao de AB-
                  If lMsErroAuto 
                     conOut(OemToAnsi("Erro na inclusao"))
                     //aLog := getAutoGRLog()
                     aLog := getAutoGRLog() //MostraErro()

                     _cErro := ""
                     If ValType(aLog) == "A" //If Len(aLog) > 0
                        For nX := 1 to Len(aLog)
                           _cErro := _cErro+aLog[nX]+" "+CRLF
                           conout(enter + aLog[nX] + enter)
                        Next
                     Else
                        _cErro := _cErro+aLog+" "+CRLF
                        conout(enter + aLog + enter)
                     EndIf
                     ::cRet := "ERRO" + enter
                     //for i := 1 to len(aLog)
                     ::cRet += _cErro + enter
                     //next i
                     conout(enter + ::cRet + enter)
                     /*
                     ::setResponse('{') 
                     ::setResponse( '"Retorno apos execucao": "' + ::cRet + '"')
                     ::setResponse('}')
                     */
                     conOut(enter + oemToAnsi("ERRO NA INCLUSAO DO AB-") + enter)
                     ::cRet := "ERRO NA INCLUSAO DO AB-"
                     ::setResponse('{' + enter) 
                     ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
                     ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
                     ::setResponse( '"col003n": '+Str(aJSon[03])+',' + enter)
                     ::setResponse( '"col004d": "'+aJSon[04]+'",' + enter)
                     ::setResponse( '"col005d": "'+aJSon[05]+'",' + enter)
                     ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
                     ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
                     ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
                     ::setResponse( '"col009d": "'+aJSon[09]+'",' + enter)
                     ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
                     ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
                     ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
                     ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
                     ::setResponse( '"col014n": '+Str(aJSon[14])+',' + enter)
                     ::setResponse( '"col015n": '+Str(aJSon[15])+',' + enter)
                     ::setResponse( '"col016n": '+Str(aJSon[16])+',' + enter)
                     ::setResponse( '"col017n": '+Str(aJSon[17])+',' + enter)
                     ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
                     ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
                     ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
                     ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
                     ::setResponse( '"col022n": '+Str(aJSon[22])+',' + enter)
                     ::setResponse( '"col023n": '+Str(aJSon[23])+',' + enter)
                     ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
                     ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
                     ::setResponse( '"col026n": '+Str(aJSon[26])+',' + enter)
                     ::setResponse( '"col027c": "ER",' + enter)
                     ::setResponse( '"col028d": "'+aJSon[28]+'",' + enter)
                     ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
                     ::setResponse( '"col030c": "'+aJSon[30]+'",' + enter)
                     ::setResponse( '"col031d": "'+aJSon[31]+'",' + enter)
                     ::setResponse( '"col032c": "'+_cErro+'",' + enter)
                     ::setResponse( '"col033c": "'+aJSon[33]+'",' + enter)
                     ::setResponse( '"col034c": "'+aJSon[34]+'",' + enter)
                     ::setResponse( '"col035c": "'+aJSon[35]+'",' + enter)
                     ::setResponse( '"col036n": '+Str(aJSon[36])+',' + enter)
                     ::setResponse( '"col037n": '+Str(aJSon[37])+',' + enter)
                     ::setResponse( '"col038n": '+Str(aJSon[38])+',' + enter)
                     ::setResponse( '"col039n": '+Str(aJSon[39])+',' + enter)
                     ::setResponse( '"col040c": "'+aJSon[40]+'",' + enter)
                     ::setResponse( '"col041n": '+Str(aJSon[41])+',' + enter)
                     ::setResponse( '"col042c": "'+aJSon[42]+'",' + enter)
                     ::setResponse( '"col043n": '+Str(aJSon[43])+',' + enter)
                     ::setResponse( '"col044c": "'+aJSon[44]+'",' + enter)
                     ::setResponse( '"col045c": "'+aJSon[45]+'",' + enter)
                     ::setResponse( '"col046c": "'+aJSon[46]+'",' + enter)
                     ::setResponse( '"col047d": "'+aJSon[47]+'"' + enter)
                     ::setResponse('}' + enter)

                     lInclui := .F.
                     DisarmTransaction()
                     break
                  Else
                     conOut(enter + oemToAnsi("Incluido do AB- com sucesso! ") + StrZero(aJSon[01],TamSX3("E2_NUM")[1]) + enter)
                     ::cRet := "Incluido do AB- com sucesso : Codigo: " + StrZero(aJSon[01],TamSX3("E2_NUM")[1])
                     ::setResponse('{' + enter) 
                     ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
                     ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
                     ::setResponse( '"col003n": '+Str(aJSon[03])+',' + enter)
                     ::setResponse( '"col004d": "'+aJSon[04]+'",' + enter)
                     ::setResponse( '"col005d": "'+aJSon[05]+'",' + enter)
                     ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
                     ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
                     ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
                     ::setResponse( '"col009d": "'+aJSon[09]+'",' + enter)
                     ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
                     ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
                     ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
                     ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
                     ::setResponse( '"col014n": '+Str(aJSon[14])+',' + enter)
                     ::setResponse( '"col015n": '+Str(aJSon[15])+',' + enter)
                     ::setResponse( '"col016n": '+Str(aJSon[16])+',' + enter)
                     ::setResponse( '"col017n": '+Str(aJSon[17])+',' + enter)
                     ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
                     ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
                     ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
                     ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
                     ::setResponse( '"col022n": '+Str(aJSon[22])+',' + enter)
                     ::setResponse( '"col023n": '+Str(aJSon[23])+',' + enter)
                     ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
                     ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
                     ::setResponse( '"col026n": '+Str(aJSon[26])+',' + enter)
                     ::setResponse( '"col027c": "IT",' + enter)
                     ::setResponse( '"col028d": "'+aJSon[28]+'",' + enter)
                     ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
                     ::setResponse( '"col030c": "'+StrZero(aJSon[01],TamSX3("E2_NUM")[1])+'",' + enter)
                     ::setResponse( '"col031d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
                     ::setResponse( '"col032c": "'+aJSon[32]+'",' + enter)
                     ::setResponse( '"col033c": "'+aJSon[33]+'",' + enter)
                     ::setResponse( '"col034c": "'+aJSon[34]+'",' + enter)
                     ::setResponse( '"col035c": "'+aJSon[35]+'",' + enter)
                     ::setResponse( '"col036n": '+Str(aJSon[36])+',' + enter)
                     ::setResponse( '"col037n": '+Str(aJSon[37])+',' + enter)
                     ::setResponse( '"col038n": '+Str(aJSon[38])+',' + enter)
                     ::setResponse( '"col039n": '+Str(aJSon[39])+',' + enter)
                     ::setResponse( '"col040c": "'+aJSon[40]+'",' + enter)
                     ::setResponse( '"col041n": '+Str(aJSon[41])+',' + enter)
                     ::setResponse( '"col042c": "'+aJSon[42]+'",' + enter)
                     ::setResponse( '"col043n": '+Str(aJSon[43])+',' + enter)
                     ::setResponse( '"col044c": "'+aJSon[44]+'",' + enter)
                     ::setResponse( '"col045c": "'+aJSon[45]+'",' + enter)
                     ::setResponse( '"col046c": "'+aJSon[46]+'",' + enter)
                     ::setResponse( '"col047d": "'+aJSon[47]+'"' + enter)
                     ::setResponse('}' + enter)
                  EndIf
               Else
                  conOut(OemToAnsi("não encontro o SE2 para o item "+AllTrim(Str(_nDeducoes))+" das deduções."))
               EndIf
               _nDeducoes++
            EndDo
         Else
            conOut(enter + oemToAnsi("NAO LOCALIZADO O ID "+AllTrim(Str(oParseJSON:col063n))+" NA SF1") + enter)
            ::cRet := "NAO LOCALIZADO O ID "+AllTrim(Str(oParseJSON:col063n))+" NA SF1"
            ::setResponse('{' + enter) 
            ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
            ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
            ::setResponse( '"col003n": '+Str(aJSon[03])+',' + enter)
            ::setResponse( '"col004d": "'+aJSon[04]+'",' + enter)
            ::setResponse( '"col005d": "'+aJSon[05]+'",' + enter)
            ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
            ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
            ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
            ::setResponse( '"col009d": "'+aJSon[09]+'",' + enter)
            ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
            ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
            ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
            ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
            ::setResponse( '"col014n": '+Str(aJSon[14])+',' + enter)
            ::setResponse( '"col015n": '+Str(aJSon[15])+',' + enter)
            ::setResponse( '"col016n": '+Str(aJSon[16])+',' + enter)
            ::setResponse( '"col017n": '+Str(aJSon[17])+',' + enter)
            ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
            ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
            ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
            ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
            ::setResponse( '"col022n": '+Str(aJSon[22])+',' + enter)
            ::setResponse( '"col023n": '+Str(aJSon[23])+',' + enter)
            ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
            ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
            ::setResponse( '"col026n": '+Str(aJSon[26])+',' + enter)
            ::setResponse( '"col027c": "ER",' + enter)
            ::setResponse( '"col028d": "'+aJSon[28]+'",' + enter)
            ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
            ::setResponse( '"col030c": "'+aJSon[30]+'",' + enter)
            ::setResponse( '"col031d": "'+aJSon[31]+'",' + enter)
            ::setResponse( '"col032c": "'+"NAO LOCALIZADO O ID "+AllTrim(Str(oParseJSON:col063n))+" NA SF1"+'",' + enter)
            ::setResponse( '"col033c": "'+aJSon[33]+'",' + enter)
            ::setResponse( '"col034c": "'+aJSon[34]+'",' + enter)
            ::setResponse( '"col035c": "'+aJSon[35]+'",' + enter)
            ::setResponse( '"col036n": '+Str(aJSon[36])+',' + enter)
            ::setResponse( '"col037n": '+Str(aJSon[37])+',' + enter)
            ::setResponse( '"col038n": '+Str(aJSon[38])+',' + enter)
            ::setResponse( '"col039n": '+Str(aJSon[39])+',' + enter)
            ::setResponse( '"col040c": "'+aJSon[40]+'",' + enter)
            ::setResponse( '"col041n": '+Str(aJSon[41])+',' + enter)
            ::setResponse( '"col042c": "'+aJSon[42]+'",' + enter)
            ::setResponse( '"col043n": '+Str(aJSon[43])+',' + enter)
            ::setResponse( '"col044c": "'+aJSon[44]+'",' + enter)
            ::setResponse( '"col045c": "'+aJSon[45]+'",' + enter)
            ::setResponse( '"col046c": "'+aJSon[46]+'",' + enter)
            ::setResponse( '"col047d": "'+aJSon[47]+'"' + enter)
             ::setResponse('}' + enter)

            lInclui := .F.
            DisarmTransaction()
            break
         EndIf
         /* RETIRADO GRAVAÇÃO DO DP, E DEIXADO SOMENTE O AB-, EM 09/01/2023 APÓS CALL COM VITOR E DIVALDO
         aVetor := {{"E2_PREFIXO" ,"PIM"                                 ,Nil},;
	                 {"E2_NUM"     ,StrZero(aJSon[01],TamSX3("E2_NUM")[1]),Nil},;
                    {"E2_PARCELA" ,""                                    ,Nil},;
                    {"E2_TIPO"	 ,"DP"                                  ,Nil},;
                    {"E2_FORNECE" ,SA2->A2_COD                           ,Nil},;
                    {"E2_LOJA"	 ,SA2->A2_LOJA                          ,Nil},;
                    {"E2_EMISSAO" ,CtoD(aJSon[28])                       ,Nil},;
                    {"E2_VENCTO"  ,CtoD(aJSon[09])                       ,Nil},;
                    {"E2_VALOR"   ,aJSon[17]                             ,Nil},;
                    {"E2_HIST"	 ,aJSon[21]                             ,Nil},;
                    {"E2_CCUSTO"  ,aJSon[18]                             ,Nil},;
                    {"E2_XORPIMS" ,"061M"                                ,Nil},;
                    {"E2_XIDPIMS" ,AllTrim(Str(aJSon[01]))               ,Nil}}

         MSExecAuto({|x,y| Fina050(x,y)},aVetor,3) //Inclusao

         If lMsErroAuto 
            conOut(OemToAnsi("Erro na inclusao"))
            //aLog := getAutoGRLog()
            aLog := getAutoGRLog() //MostraErro()

            _cErro := ""
            If ValType(aLog) == "A" //If Len(aLog) > 0
               For nX := 1 to Len(aLog)
                  _cErro := _cErro+aLog[nX]+" "+CRLF
                  conout(enter + aLog[nX] + enter)
               Next
            Else
               _cErro := _cErro+aLog+" "+CRLF
               conout(enter + aLog + enter)
            EndIf
            ::cRet := "ERRO" + enter
            //for i := 1 to len(aLog)
            ::cRet += _cErro + enter
            //next i
            conout(enter + ::cRet + enter)
            conOut(enter + oemToAnsi("ERRO NA INCLUSAO") + enter)
            ::cRet := "ERRO NA INCLUSAO"
            ::setResponse('{' + enter) 
            ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
            ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
            ::setResponse( '"col003n": '+Str(aJSon[03])+',' + enter)
            ::setResponse( '"col004d": "'+aJSon[04]+'",' + enter)
            ::setResponse( '"col005d": "'+aJSon[05]+'",' + enter)
            ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
            ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
            ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
            ::setResponse( '"col009d": "'+aJSon[09]+'",' + enter)
            ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
            ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
            ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
            ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
            ::setResponse( '"col014n": '+Str(aJSon[14])+',' + enter)
            ::setResponse( '"col015n": '+Str(aJSon[15])+',' + enter)
            ::setResponse( '"col016n": '+Str(aJSon[16])+',' + enter)
            ::setResponse( '"col017n": '+Str(aJSon[17])+',' + enter)
            ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
            ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
            ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
            ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
            ::setResponse( '"col022n": '+Str(aJSon[22])+',' + enter)
            ::setResponse( '"col023n": '+Str(aJSon[23])+',' + enter)
            ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
            ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
            ::setResponse( '"col026n": '+Str(aJSon[26])+',' + enter)
            ::setResponse( '"col027c": "ER",' + enter)
            ::setResponse( '"col028d": "'+aJSon[28]+'",' + enter)
            ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
            ::setResponse( '"col030c": "'+aJSon[30]+'",' + enter)
            ::setResponse( '"col031d": "'+aJSon[31]+'",' + enter)
            ::setResponse( '"col032c": "'+_cErro+'",' + enter)
            ::setResponse( '"col033c": "'+aJSon[33]+'",' + enter)
            ::setResponse( '"col034c": "'+aJSon[34]+'",' + enter)
            ::setResponse( '"col035c": "'+aJSon[35]+'",' + enter)
            ::setResponse( '"col036n": '+Str(aJSon[36])+',' + enter)
            ::setResponse( '"col037n": '+Str(aJSon[37])+',' + enter)
            ::setResponse( '"col038n": '+Str(aJSon[38])+',' + enter)
            ::setResponse( '"col039n": '+Str(aJSon[39])+',' + enter)
            ::setResponse( '"col040c": "'+aJSon[40]+'",' + enter)
            ::setResponse( '"col041n": '+Str(aJSon[41])+',' + enter)
            ::setResponse( '"col042c": "'+aJSon[42]+'",' + enter)
            ::setResponse( '"col043n": '+Str(aJSon[43])+',' + enter)
            ::setResponse( '"col044c": "'+aJSon[44]+'",' + enter)
            ::setResponse( '"col045c": "'+aJSon[45]+'",' + enter)
            ::setResponse( '"col046c": "'+aJSon[46]+'",' + enter)
            ::setResponse( '"col047d": "'+aJSon[47]+'"' + enter)
            ::setResponse('}' + enter)

            lInclui := .F.
            DisarmTransaction()
            break
         Else
            conOut(enter + oemToAnsi("Incluido com sucesso! ") + StrZero(aJSon[01],TamSX3("E2_NUM")[1]) + enter)
            ::cRet := "Incluido com sucesso : Codigo: " + StrZero(aJSon[01],TamSX3("E2_NUM")[1])
            ::setResponse('{' + enter) 
            ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
            ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
            ::setResponse( '"col003n": '+Str(aJSon[03])+',' + enter)
            ::setResponse( '"col004d": "'+aJSon[04]+'",' + enter)
            ::setResponse( '"col005d": "'+aJSon[05]+'",' + enter)
            ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
            ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
            ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
            ::setResponse( '"col009d": "'+aJSon[09]+'",' + enter)
            ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
            ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
            ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
            ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
            ::setResponse( '"col014n": '+Str(aJSon[14])+',' + enter)
            ::setResponse( '"col015n": '+Str(aJSon[15])+',' + enter)
            ::setResponse( '"col016n": '+Str(aJSon[16])+',' + enter)
            ::setResponse( '"col017n": '+Str(aJSon[17])+',' + enter)
            ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
            ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
            ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
            ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
            ::setResponse( '"col022n": '+Str(aJSon[22])+',' + enter)
            ::setResponse( '"col023n": '+Str(aJSon[23])+',' + enter)
            ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
            ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
            ::setResponse( '"col026n": '+Str(aJSon[26])+',' + enter)
            ::setResponse( '"col027c": "IT",' + enter)
            ::setResponse( '"col028d": "'+aJSon[28]+'",' + enter)
            ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
            ::setResponse( '"col030c": "'+StrZero(aJSon[01],TamSX3("E2_NUM")[1])+'",' + enter)
            ::setResponse( '"col031d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
            ::setResponse( '"col032c": "'+aJSon[32]+'",' + enter)
            ::setResponse( '"col033c": "'+aJSon[33]+'",' + enter)
            ::setResponse( '"col034c": "'+aJSon[34]+'",' + enter)
            ::setResponse( '"col035c": "'+aJSon[35]+'",' + enter)
            ::setResponse( '"col036n": '+Str(aJSon[36])+',' + enter)
            ::setResponse( '"col037n": '+Str(aJSon[37])+',' + enter)
            ::setResponse( '"col038n": '+Str(aJSon[38])+',' + enter)
            ::setResponse( '"col039n": '+Str(aJSon[39])+',' + enter)
            ::setResponse( '"col040c": "'+aJSon[40]+'",' + enter)
            ::setResponse( '"col041n": '+Str(aJSon[41])+',' + enter)
            ::setResponse( '"col042c": "'+aJSon[42]+'",' + enter)
            ::setResponse( '"col043n": '+Str(aJSon[43])+',' + enter)
            ::setResponse( '"col044c": "'+aJSon[44]+'",' + enter)
            ::setResponse( '"col045c": "'+aJSon[45]+'",' + enter)
            ::setResponse( '"col046c": "'+aJSon[46]+'",' + enter)
            ::setResponse( '"col047d": "'+aJSon[47]+'"' + enter)
            ::setResponse('}' + enter)
         EndIf
         */
      EndIf
   Else
      conOut(enter + oemToAnsi("ERRO NA VALIDACAO") + enter)
      ::cRet := "ERRO NA VALIDACAO"
      ::setResponse('{' + enter) 
      ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
      ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
      ::setResponse( '"col003n": '+Str(aJSon[03])+',' + enter)
      ::setResponse( '"col004d": "'+aJSon[04]+'",' + enter)
      ::setResponse( '"col005d": "'+aJSon[05]+'",' + enter)
      ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
      ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
      ::setResponse( '"col008n": '+Str(aJSon[08])+',' + enter)
      ::setResponse( '"col009d": "'+aJSon[09]+'",' + enter)
      ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
      ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
      ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
      ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
      ::setResponse( '"col014n": '+Str(aJSon[14])+',' + enter)
      ::setResponse( '"col015n": '+Str(aJSon[15])+',' + enter)
      ::setResponse( '"col016n": '+Str(aJSon[16])+',' + enter)
      ::setResponse( '"col017n": '+Str(aJSon[17])+',' + enter)
      ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
      ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
      ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
      ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
      ::setResponse( '"col022n": '+Str(aJSon[22])+',' + enter)
      ::setResponse( '"col023n": '+Str(aJSon[23])+',' + enter)
      ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
      ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
      ::setResponse( '"col026n": '+Str(aJSon[26])+',' + enter)
      ::setResponse( '"col027c": "ER",' + enter)
      ::setResponse( '"col028d": "'+aJSon[28]+'",' + enter)
      ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
      ::setResponse( '"col030c": "'+aJSon[30]+'",' + enter)
      ::setResponse( '"col031d": "'+aJSon[31]+'",' + enter)
      ::setResponse( '"col032c": "'+_cRetErr+'",' + enter)
      ::setResponse( '"col033c": "'+aJSon[33]+'",' + enter)
      ::setResponse( '"col034c": "'+aJSon[34]+'",' + enter)
      ::setResponse( '"col035c": "'+aJSon[35]+'",' + enter)
      ::setResponse( '"col036n": '+Str(aJSon[36])+',' + enter)
      ::setResponse( '"col037n": '+Str(aJSon[37])+',' + enter)
      ::setResponse( '"col038n": '+Str(aJSon[38])+',' + enter)
      ::setResponse( '"col039n": '+Str(aJSon[39])+',' + enter)
      ::setResponse( '"col040c": "'+aJSon[40]+'",' + enter)
      ::setResponse( '"col041n": '+Str(aJSon[41])+',' + enter)
      ::setResponse( '"col042c": "'+aJSon[42]+'",' + enter)
      ::setResponse( '"col043n": '+Str(aJSon[43])+',' + enter)
      ::setResponse( '"col044c": "'+aJSon[44]+'",' + enter)
      ::setResponse( '"col045c": "'+aJSon[45]+'",' + enter)
      ::setResponse( '"col046c": "'+aJSon[46]+'",' + enter)
      ::setResponse( '"col047d": "'+aJSon[47]+'"' + enter)
      ::setResponse('}' + enter)
   EndIf
EndIf

END TRANSACTION

RpcClearEnv()

Return .t.

/*/{Protheus.doc} PIMS091M
Serviço POST para Retorno de Pesagem
@author Max Ivan (Nexus)
@since 11/05/20
@version P12
@uso MP12
@type function
/*/
WSRESTFUL INT_PIMS_091M DESCRIPTION "Serviço REST para Retorno de Pesagem"

//COLOCAR CAMPOS OBRIGATORIOS ABAIXO
WSDATA cRet		AS STRING

WSMETHOD POST DESCRIPTION "POST / Retorno de Pesagem" WSSYNTAX ""

END WSRESTFUL

WSMETHOD POST WSRECEIVE RECEIVE WSSERVICE INT_PIMS_091M

Local aJSon         := {}
Local aLog		    := {}
Local cJson         := ::getContent()
Local cUniEmp		:= 	""
Local cFilEmp		:= 	""
Local lInclui       := .T.
Local _lTdOk        := .T.
Local _cRetInco     := ""
Local _cRetJson     := ""

Local _aCabPV  := {}	 // Array do cabeçalho
Local aLinha   := {}	 // Array dos itens
Local aItens   := {}
Local nSaveSx8 := 0
Local cNumero  := ''
Local _nQtde   := 0

Local nOpcx    := 3
Local nCount   := 1

Private lMsErroAuto    := .F.
Private lMsErroHelp    := .T.
Private lAutoErrNoFile := .T.

oParseJSON := nil

::setContentType("application/json")
FWJsonDeserialize(DecodeUtf8(cJson), @oParseJSON)

cUniEmp := oParseJSON:col002c
cFilEmp := oParseJSON:col003c

RpcSetType(3)
RpcSetEnv(cUniEmp,cFilEmp,"","","FAT")
cEmpAnt := cUniEmp
cFilAnt := cFilEmp

BEGIN TRANSACTION  

   AAdd(aJSon,ValInfo(oParseJSON:COL001N,"N")) //Id sequencial
   AAdd(aJSon,ValInfo(oParseJSON:COL002C,"C")) //Empresa ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL003C,"C")) //Centro ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL004C,"C")) //Número da ordem de carregamento no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL005C,"C")) //Números dos documentos gerados no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL006C,"C")) //Código do produto no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL007C,"C")) //Descrição produto
   AAdd(aJSon,ValInfo(oParseJSON:COL008C,"C")) //Unidade de medida
   AAdd(aJSon,ValInfo(oParseJSON:COL009C,"C")) //Código do deposito (armazém)
   AAdd(aJSon,ValInfo(oParseJSON:COL010C,"C")) //Descrição do deposito (armazém)
   AAdd(aJSon,ValInfo(oParseJSON:COL011N,"N")) //Quantidade liberada para carregamento
   AAdd(aJSon,ValInfo(oParseJSON:COL012C,"C")) //Código da transportadora no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL013C,"C")) //Descrição da transportadora
   AAdd(aJSon,ValInfo(oParseJSON:COL014C,"C")) //Código do CNPJ/CPF
   AAdd(aJSon,ValInfo(oParseJSON:COL015C,"C")) //Placa do caminhão
   AAdd(aJSon,ValInfo(oParseJSON:COL016C,"C")) //Placa da carreta 1
   AAdd(aJSon,ValInfo(oParseJSON:COL017C,"C")) //Placa da carreta 2
   AAdd(aJSon,ValInfo(oParseJSON:COL018C,"C")) //Unidade federativa da placa do caminhão
   AAdd(aJSon,ValInfo(oParseJSON:COL019C,"C")) //Unidade federativa da placa da Carreta 1
   AAdd(aJSon,ValInfo(oParseJSON:COL020C,"C")) //Unidade federativa da placa da Carreta 2
   AAdd(aJSon,ValInfo(oParseJSON:COL021C,"C")) //Nome do motorista
   AAdd(aJSon,ValInfo(oParseJSON:COL022C,"C")) //Identidade do motorista
   AAdd(aJSon,ValInfo(oParseJSON:COL023C,"C")) //Código do cliente no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL024C,"C")) //Descrição do cliente
   AAdd(aJSon,ValInfo(oParseJSON:COL025C,"C")) //Código do CNPJ/CPF do cliente
   AAdd(aJSon,ValInfo(oParseJSON:COL026C,"C")) //Safra do pedido
   AAdd(aJSon,ValInfo(oParseJSON:COL027C,"C")) //Situação do registro para o PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL028C,"C")) //Situação do registro para o ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL029C,"C")) //Instancia do PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL030N,"N")) //Número da pesagem no PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL031D,"C")) //Data da ordem no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL032N,"N")) //Peso Bruto (kg)
   AAdd(aJSon,ValInfo(oParseJSON:COL033N,"N")) //Peso Tara (kg)
   AAdd(aJSon,ValInfo(oParseJSON:COL034N,"N")) //Peso Líquido (kg)
   AAdd(aJSon,ValInfo(oParseJSON:COL035N,"N")) //Quantidade a faturar (kg ou l)
   AAdd(aJSon,ValInfo(oParseJSON:COL036C,"C")) //Número dos lacres da carga
   AAdd(aJSon,ValInfo(oParseJSON:COL037D,"C")) //Data da leitura no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL038N,"N")) //Quantidade na seta
   AAdd(aJSon,ValInfo(oParseJSON:COL039N,"N")) //Quantidade na balança
   AAdd(aJSon,ValInfo(oParseJSON:COL040C,"C")) //Código do tanque da retirada
   AAdd(aJSon,ValInfo(oParseJSON:COL041N,"N")) //Temperatura do tanque do veículo
   AAdd(aJSon,ValInfo(oParseJSON:COL042N,"N")) //Massa especifica
   AAdd(aJSon,ValInfo(oParseJSON:COL043N,"N")) //Massa especifica a 20º
   AAdd(aJSon,ValInfo(oParseJSON:COL044N,"N")) //Fator de redução
   AAdd(aJSon,ValInfo(oParseJSON:COL045N,"N")) //Diferença seta-balança
   AAdd(aJSon,ValInfo(oParseJSON:COL046D,"C")) //Data da entrada
   AAdd(aJSon,ValInfo(oParseJSON:COL047C,"C")) //Hora da entrada
   AAdd(aJSon,ValInfo(oParseJSON:COL048D,"C")) //Data da saída
   AAdd(aJSon,ValInfo(oParseJSON:COL049C,"C")) //Hora da saída
   AAdd(aJSon,ValInfo(oParseJSON:COL050N,"N")) //Grau de INPM
   AAdd(aJSon,ValInfo(oParseJSON:COL051C,"C")) //Observação 1
   AAdd(aJSon,ValInfo(oParseJSON:COL052C,"C")) //Observação 2
   AAdd(aJSon,ValInfo(oParseJSON:COL053C,"C")) //Numero do Certificado PIMS (para alcool)
   AAdd(aJSon,ValInfo(oParseJSON:COL054D,"C")) //Data e hora do envio do envio pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL055D,"C")) //Data e hora da alimentação pelo PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL056D,"C")) //Data e hora da finalização pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL057C,"C")) //Mensagem de erro

   If aJSon[28] $ "01/02" .and. aJSon[35] > 0
      _cNumPV := AllTrim(aJSon[04]) //AllTrim(Str(aJSon[04]))
      //conOut(OemToAnsi("091M - STATUS 02 - COL004N: "+_cNumPV))
      //_cNumPV := StrZero(Val(_cNumPV),TamSX3("C6_NUM")[1]+TamSX3("C6_ITEM")[1])
      conOut(OemToAnsi("091M - STATUS 02 - COL004C: "+_cNumPV))
      SC5->(DbSetOrder(1))
      If SC5->(DbSeek(xFilial("SC5")+SubsTr(_cNumPV,1,TamSX3("C5_NUM")[1])))
         conOut(OemToAnsi("091M - STATUS 02 - ENTROU NO SC5"))
         Aadd(_aCabPV,{"C5_NUM"    , SubsTr(_cNumPV,1,TamSX3("C5_NUM")[1]) ,Nil})
         //Aadd(_aCabPV,{"C5_X_PESA" , "J"                                   ,Nil})
         Aadd(_aCabPV,{"C5_PESOL"  , aJSon[34] ,Nil})
         Aadd(_aCabPV,{"C5_PBRUTO" , aJSon[32] ,Nil})
         Aadd(_aCabPV,{"C5_MENNOTA", "NUMERO DA PESAGEM: "+AllTrim(Str(aJSon[30]))+;
                                     " LACRES: "+AllTrim(aJSon[36])+;
                                     " TEMP.: "+AllTrim(TransForm(aJSon[41],"@E 999.9"))+;
                                     " FATOR RED.: "+AllTrim(TransForm(aJSon[44],"@E 999.9999"))+;
                                     " ME 20o: "+AllTrim(TransForm(aJSon[43],"@E 999.99")),Nil})

         /* RETIRADO EM 05/08/2022 à pedido do Victor por Skype
         Aadd(_aCabPV,{"C5_MENNOTA", "NUMERO DA PESAGEM: "+AllTrim(Str(aJSon[30]))+;
                                     " LACRES: "+AllTrim(aJSon[36])+;
                                     " PESO BRUTO: "+AllTrim(TransForm(aJSon[32],"@E 999,999"))+;
                                     " PESO TARA: "+AllTrim(TransForm(aJSon[33],"@E 999,999"))+;
                                     " PESO LIQUIDO: "+AllTrim(TransForm(aJSon[34],"@E 999,999"))+;
                                     " QUANTIDADE A FATURAR: "+AllTrim(TransForm(aJSon[35],"@E 999,999.999999"))+;
                                     " DATA SAIDA: "+AllTrim(aJSon[48])+;
                                     " TEMP.: "+AllTrim(TransForm(aJSon[41],"@E 999.9"))+;
                                     " FATOR RED.: "+AllTrim(TransForm(aJSon[44],"@E 999.9999"))+;
                                     " ME 20o: "+AllTrim(TransForm(aJSon[43],"@E 999.99")),Nil})
         */

         SC6->(DbSetOrder(1))
         If SC6->(DbSeek(xFilial("SC6")+_cNumPV))
            conOut(OemToAnsi("091M - STATUS 02 - ENTROU NO SC6"))
            aLinha := {}
			SB1->(DbSetOrder(1))
			SB1->(DbSeek(xFilial("SB1")+SC6->C6_PRODUTO))
			If AllTrim(SC6->C6_SEGUM) $ "KG|L" .and. SB1->B1_CONV > 0 .and. !Empty(SB1->B1_TIPCONV)
				_nQtde := If(SB1->B1_TIPCONV=="D",aJSon[35]/SB1->B1_CONV,aJSon[35]*SB1->B1_CONV)
			Else
				_nQtde := aJSon[35]
			EndIf
            //aadd(aLinha,{"LINPOS",     "C6_ITEM",     StrZero(nX,2)})
            //aadd(aLinha,{"AUTDELETA",  "N",           Nil})
            AAdd(aLinha,{"C6_FILIAL" , SC6->C6_FILIAL ,Nil})
            aadd(aLinha,{"C6_ITEM"   , SC6->C6_ITEM   , Nil})
            aadd(aLinha,{"C6_PRODUTO", SC6->C6_PRODUTO, Nil})
            aadd(aLinha,{"C6_QTDVEN" , _nQtde         , Nil})
            aadd(aLinha,{"C6_PRCVEN" , SC6->C6_PRCVEN , Nil})
            aadd(aLinha,{"C6_TES"    , SC6->C6_TES    , Nil})
            aadd(aLinha,{"C6_CONTRAT" , SC6->C6_CONTRAT, Nil}) //  24-05-2022
            aadd(aLinha,{"C6_ITEMCON" , SC6->C6_ITEMCON, Nil}) //  24-05-2022
            If SC6->(FieldPos("C6_X_ORIQT")) > 0 .and. SC6->C6_X_ORIQT == 0
               aadd(aLinha,{"C6_X_ORIQT" , SC6->C6_QTDVEN , Nil})
            EndIf
            aadd(aItens, aLinha)
            
            nOpcx := 4

            lMSHelpAuto := .F.
            lMsErroAuto := .F.

            If Empty(SC5->C5_NOTA)
               MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, _aCabPV, aItens, nOpcX, .F.)
            Else // Se o Pedido já estiver faturado
               lMsErroAuto := .T.
            EndIf

            If lMsErroAuto
               //MostraErro()
               _cRetErr := ""
               If Empty(SC5->C5_NOTA)
                  conOut(OemToAnsi("091M - STATUS 02 - ERRO NA ALTERACAO OU PEDIDO"))
                  aErroAuto := GetAutoGRLog()
                  For nCount := 1 To Len(aErroAuto)
                     cLogErro := StrTran(StrTran(aErroAuto[nCount], "<", ""), "-", "") + " " //+ enter
                     ConOut(cLogErro)
                     _cRetErr += cLogErro
                  Next nCount
               Else
                  conOut(OemToAnsi("091M - STATUS 02 - PEDIDO JA FATURADO"))
               EndIf
               //cLogErro := TrataErro(MostraErro()) // –> Trata o erro para devolver para o client.
               //ConOut(cLogErro)

               ::cRet := "ERRO" + enter
               ::setResponse('{' + enter) 
               ::setResponse( '"col001n": '+AllTrim(Str(aJSon[01]))+',' + enter)
               ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
               ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
               ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
               ::setResponse( '"col005c": "'+If(Empty(SC5->C5_NOTA),aJSon[05],SC5->C5_SERIE+SC5->C5_NOTA)+'",' + enter)
               ConOut(If(Empty(SC5->C5_NOTA),aJSon[05],SC5->C5_SERIE+SC5->C5_NOTA))
               ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
               ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
               ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
               ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
               ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
               ::setResponse( '"col011n": '+AllTrim(Str(aJSon[11]))+',' + enter)
               ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
               ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
               ::setResponse( '"col014c": "'+aJSon[14]+'",' + enter)
               ::setResponse( '"col015c": "'+aJSon[15]+'",' + enter)
               ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
               ::setResponse( '"col017c": "'+aJSon[17]+'",' + enter)
               ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
               ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
               ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
               ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
               ::setResponse( '"col022c": "'+aJSon[22]+'",' + enter)
               ::setResponse( '"col023c": "'+aJSon[23]+'",' + enter)
               ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
               ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
               ::setResponse( '"col026c": "'+aJSon[26]+'",' + enter)
               ::setResponse( '"col027c": "'+aJSon[27]+'",' + enter)
               ::setResponse( '"col028c": "'+If(Empty(SC5->C5_NOTA),"01","03")+'",' + enter)
               ConOut(If(Empty(SC5->C5_NOTA),"01","03"))
               ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
               ::setResponse( '"col030n": '+AllTrim(Str(aJSon[30]))+',' + enter)
               ::setResponse( '"col031d": "'+If(Empty(SC5->C5_NOTA),aJSon[31],DtoC(Date())+' '+Time())+'",' + enter)
               ConOut(If(Empty(SC5->C5_NOTA),aJSon[31],DtoC(Date())+' '+Time()))
               ::setResponse( '"col032n": '+AllTrim(Str(aJSon[32]))+',' + enter)
               ::setResponse( '"col033n": '+AllTrim(Str(aJSon[33]))+',' + enter)
               ::setResponse( '"col034n": '+AllTrim(Str(aJSon[34]))+',' + enter)
               ::setResponse( '"col035n": '+AllTrim(Str(aJSon[35]))+',' + enter)
               ::setResponse( '"col036c": "'+aJSon[36]+'",' + enter)
               ::setResponse( '"col037d": "'+aJSon[37]+'",' + enter)
               ::setResponse( '"col038n": '+AllTrim(Str(aJSon[38]))+',' + enter)
               ::setResponse( '"col039n": '+AllTrim(Str(aJSon[39]))+',' + enter)
               ::setResponse( '"col040c": "'+aJSon[40]+'",' + enter)
               ::setResponse( '"col041n": '+AllTrim(Str(aJSon[41]))+',' + enter)
               ::setResponse( '"col042n": '+AllTrim(Str(aJSon[42]))+',' + enter)
               ::setResponse( '"col043n": '+AllTrim(Str(aJSon[43]))+',' + enter)
               ::setResponse( '"col044n": '+AllTrim(Str(aJSon[44]))+',' + enter)
               ::setResponse( '"col045n": '+AllTrim(Str(aJSon[45]))+',' + enter)
               ::setResponse( '"col046d": "'+aJSon[46]+'",' + enter)
               ::setResponse( '"col047c": "'+aJSon[47]+'",' + enter)
               ::setResponse( '"col048d": "'+aJSon[48]+'",' + enter)
               ::setResponse( '"col049c": "'+aJSon[49]+'",' + enter)
               ::setResponse( '"col050n": '+AllTrim(Str(aJSon[50]))+',' + enter)
               ::setResponse( '"col051c": "'+aJSon[51]+'",' + enter)
               ::setResponse( '"col052c": "'+aJSon[52]+'",' + enter)
               ::setResponse( '"col053c": "'+aJSon[53]+'",' + enter)
               ::setResponse( '"col054d": "'+aJSon[54]+'",' + enter)
               ::setResponse( '"col055d": "'+aJSon[55]+'",' + enter)
               ::setResponse( '"col056d": "'+aJSon[56]+'",' + enter)
               ::setResponse( '"col057c": "'+SubsTr(_cRetErr,1,250)+'"' + enter)
               ::setResponse('}' + enter)
               DisarmTransaction()
               break
            Else
               conOut(OemToAnsi("091M - STATUS 02 - ALTERACAO DO PV: "+_cNumPV+" REALIZADA COM SUCESSO!!!"))

               ::cRet := "Alteracao realizada com sucesso : PV: " + _cNumPV
         
               ::setResponse('{' + enter) 
               ::setResponse( '"col001n": '+AllTrim(Str(aJSon[01]))+',' + enter)
               ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
               ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
               ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
               ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
               ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
               ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
               ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
               ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
               ::setResponse( '"col010c": "'+aJSon[10]+'",' + enter)
               ::setResponse( '"col011n": '+AllTrim(Str(aJSon[11]))+',' + enter)
               ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
               ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
               ::setResponse( '"col014c": "'+aJSon[14]+'",' + enter)
               ::setResponse( '"col015c": "'+aJSon[15]+'",' + enter)
               ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
               ::setResponse( '"col017c": "'+aJSon[17]+'",' + enter)
               ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
               ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
               ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
               ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
               ::setResponse( '"col022c": "'+aJSon[22]+'",' + enter)
               ::setResponse( '"col023c": "'+aJSon[23]+'",' + enter)
               ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
               ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
               ::setResponse( '"col026c": "'+aJSon[26]+'",' + enter)
               ::setResponse( '"col027c": "'+aJSon[27]+'",' + enter)
               ::setResponse( '"col028c": "02",' + enter)
               ::setResponse( '"col029c": "'+aJSon[29]+'",' + enter)
               ::setResponse( '"col030n": '+AllTrim(Str(aJSon[30]))+',' + enter)
               ::setResponse( '"col031d": "'+aJSon[31]+'",' + enter)
               ::setResponse( '"col032n": '+AllTrim(Str(aJSon[32]))+',' + enter)
               ::setResponse( '"col033n": '+AllTrim(Str(aJSon[33]))+',' + enter)
               ::setResponse( '"col034n": '+AllTrim(Str(aJSon[34]))+',' + enter)
               ::setResponse( '"col035n": '+AllTrim(Str(aJSon[35]))+',' + enter)
               ::setResponse( '"col036c": "'+aJSon[36]+'",' + enter)
               ::setResponse( '"col037d": "'+aJSon[37]+'",' + enter)
               ::setResponse( '"col038n": '+AllTrim(Str(aJSon[38]))+',' + enter)
               ::setResponse( '"col039n": '+AllTrim(Str(aJSon[39]))+',' + enter)
               ::setResponse( '"col040c": "'+aJSon[40]+'",' + enter)
               ::setResponse( '"col041n": '+AllTrim(Str(aJSon[41]))+',' + enter)
               ::setResponse( '"col042n": '+AllTrim(Str(aJSon[42]))+',' + enter)
               ::setResponse( '"col043n": '+AllTrim(Str(aJSon[43]))+',' + enter)
               ::setResponse( '"col044n": '+AllTrim(Str(aJSon[44]))+',' + enter)
               ::setResponse( '"col045n": '+AllTrim(Str(aJSon[45]))+',' + enter)
               ::setResponse( '"col046d": "'+aJSon[46]+'",' + enter)
               ::setResponse( '"col047c": "'+aJSon[47]+'",' + enter)
               ::setResponse( '"col048d": "'+aJSon[48]+'",' + enter)
               ::setResponse( '"col049c": "'+aJSon[49]+'",' + enter)
               ::setResponse( '"col050n": '+AllTrim(Str(aJSon[50]))+',' + enter)
               ::setResponse( '"col051c": "'+aJSon[51]+'",' + enter)
               ::setResponse( '"col052c": "'+aJSon[52]+'",' + enter)
               ::setResponse( '"col053c": "'+aJSon[53]+'",' + enter)
               ::setResponse( '"col054d": "'+aJSon[54]+'",' + enter)
               ::setResponse( '"col055d": "'+aJSon[55]+'",' + enter)
               ::setResponse( '"col056d": "'+aJSon[56]+'",' + enter)
               ::setResponse( '"col057c": "'+aJSon[57]+'"' + enter)
               ::setResponse('}' + enter)
            EndIf
         EndIf
      EndIf
   EndIf

END TRANSACTION

RpcClearEnv()

Return .t.


/*/{Protheus.doc} PIMS071M
Serviço POST para Inserção de NF Mensal e Diária de Cana
@author Max Ivan (Nexus)
@since 11/05/20
@version P12
@uso MP12
@type function
/*/
WSRESTFUL INT_PIMS_071M DESCRIPTION "Serviço REST para Retorno de Pesagem"

//COLOCAR CAMPOS OBRIGATORIOS ABAIXO
WSDATA cRet		AS STRING

WSMETHOD POST DESCRIPTION "POST / Retorno de Pesagem" WSSYNTAX ""

END WSRESTFUL

WSMETHOD POST WSRECEIVE RECEIVE WSSERVICE INT_PIMS_071M



Local aJSon         := {}
Local aLog		    := {}
Local cJson         := ::getContent()
Local cUniEmp		:= 	""
Local cFilEmp		:= 	""
Local lInclui       := .T.
Local _lTdOk        := .T.
Local _cRetInco     := ""
Local _cRetJson     := ""

Local _aCabPV  := {}	 // Array do cabeçalho
Local aLinha   := {}	 // Array dos itens
Local aItens   := {}
Local nSaveSx8 := 0
Local cNumero  := ''

Local nOpcx    := 3
Local _nI      := 1 
Local nCount   := 1

Private lMsErroAuto    := .F.
Private lMsErroHelp    := .T.
Private lAutoErrNoFile := .T.

conOut(OemToAnsi("071M: INICIAR LEITURA JSON"))

oParseJSON := nil

::setContentType("application/json")
FWJsonDeserialize(DecodeUtf8(cJson), @oParseJSON)

cUniEmp := oParseJSON:col007c
cFilEmp := oParseJSON:col008c

conOut(OemToAnsi("071M: json "+cJson))

conOut(OemToAnsi("071M: LEU EMPRESA/FILIAL"))

RpcSetType(3)
RpcSetEnv(cUniEmp,cFilEmp,"","","COM")
cEmpAnt := cUniEmp
cFilAnt := cFilEmp

conOut(OemToAnsi("071M: CARREGOU EMPRESA/FILIAL"))

BEGIN TRANSACTION  

   AAdd(aJSon,ValInfo(oParseJSON:COL001N,"N")) //Id sequencial
   AAdd(aJSon,ValInfo(oParseJSON:COL002C,"C")) //Código da Instancia do PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL003N,"N")) //Número PIMS da Nota Fiscal
   AAdd(aJSon,ValInfo(oParseJSON:COL004C,"C")) //Série da NF do PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL005C,"C")) //Identificador da origem no PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL006C,"C")) //Tipo da nota fiscal
   AAdd(aJSon,ValInfo(oParseJSON:COL007C,"C")) //Código da empresa no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL008C,"C")) //Código da filial no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL009C,"C")) //Código da safra
   AAdd(aJSon,ValInfo(oParseJSON:COL010D,"C")) //Data do lançamento
   AAdd(aJSon,ValInfo(oParseJSON:COL011C,"C")) //Tipo do Fornecedor
   AAdd(aJSon,ValInfo(oParseJSON:COL012N,"N")) //Código do fornecedor no PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL013C,"C")) //Código do fornecedor no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL014C,"C")) //Código do contrato no PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL015C,"C")) //Código do contrato no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL016C,"C")) //Código do fundo agrícola no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL017C,"C")) //Número INCRA da Fazenda
   AAdd(aJSon,ValInfo(oParseJSON:COL018C,"C")) //Observação fiscal
   AAdd(aJSon,ValInfo(oParseJSON:COL019C,"C")) //Informa se é nota de complemento
   AAdd(aJSon,ValInfo(oParseJSON:COL020C,"C")) //Gera contabilização
   AAdd(aJSon,ValInfo(oParseJSON:COL021C,"C")) //Nota fiscal complementada
   AAdd(aJSon,ValInfo(oParseJSON:COL022N,"N")) //Valor da retenção de safra
   AAdd(aJSon,ValInfo(oParseJSON:COL023D,"C")) //Vencimento da retenção de safra
   AAdd(aJSon,ValInfo(oParseJSON:COL024C,"C")) //Código do Processo de geração
   AAdd(aJSon,ValInfo(oParseJSON:COL025C,"C")) //Identificador do lote de dados
   AAdd(aJSon,ValInfo(oParseJSON:COL026C,"C")) //Mensagem PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL027C,"C")) //Status do registro
   AAdd(aJSon,ValInfo(oParseJSON:COL028D,"C")) //Data do envio pelo PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL029D,"C")) //Data da integração pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL030C,"C")) //Nº da nota fiscal gerada no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL031C,"C")) //Nº série da NF no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL032C,"C")) //Mensagem de log do ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL033C,"C")) //Natureza da Operação

   conOut(OemToAnsi("071M: VARIAVEIS PRINCIPAIS"))

   AAdd(aJSon,oParseJSON:itens) //Produtos

   conOut(OemToAnsi("071M: CARREGOU ITENS"))
   conOut(OemToAnsi("071M: PRODUTO 1: "+aJSon[34][1]:COL004C))
   _lTdOK   := .T.
   _cRetErr := ""
   _cSerie  := ""
   _cNumNF  := ""
   _cTES    := ""

   If AllTrim(aJSon[27]) $ "NI|ES"
      If aJSon[01] > 0
         If AllTrim(aJson[06]) $ "1|2"
            _cSerie := If(AllTrim(aJson[06])=="1","1","2")
            _cTES   := If(AllTrim(aJson[06])=="1",GetNewPar("MV_X_TESDI", "086"),GetNewPar("MV_X_TESME", "087"))
            SF1->(DbOrderNickName("XORIDPIMS"))
            If AllTrim(aJSon[27]) == "NI" .AND. !SF1->(DbSeek(xFilial("SF1")+"071M"+Padr(AllTrim(Str(aJSon[01])),TamSx3("F1_XIDPIMS")[1])))
               SX5->(DbSetOrder(1))
               If SX5->(DbSeek(cFilAnt+"01"+_cSerie))
                  _cNumNF  := Alltrim(SX5->X5_DESCRI) //AllTrim(FWGetSX5('01',_cSerie)[1][4])
                  SA2->(DbSetOrder(1))
                  If SA2->(DbSeek(xFilial("SA2")+aJson[13]))
                     SB1->(DbSetOrder(1))
                     For _nI := 1 To Len(aJSon[34])
                        If !SB1->(DbSeek(xFilial("SB1")+aJSon[34][_nI]:COL004C))
                           _lTdOK   := .F.
                           _cRetErr := "NAO LOCALIZADO O PRODUTO: "+aJSon[34][_nI]:COL004C
                        EndIf
                     Next
                  Else
                     _lTdOK   := .F.
                     _cRetErr := "FORNECEDOR (COL013C) NAO LOCALIZADO"
                  EndIf
               Else
                  _lTdOK   := .F.
                  _cRetErr := "NAO LOCALIZADO TABELA 01 NO SX5 PARA SERIE: "+_cSerie
               EndIf
            Else
               _lTdOK   := .F.
               _cRetErr := "JA EXISTE NF PARA O ID COM NUMERO: "+SF1->F1_DOC
            EndIf
         Else
            _lTdOK   := .F.
            _cRetErr := "COL006 DIFERENTE DE 1 E 2"
         EndIf
      Else
         _lTdOK   := .F.
         _cRetErr := "COL001N EM BRANCO"
      EndIf
   Else
      _lTdOK   := .F.
      _cRetErr := "COL027 DIFERENTE DE NI OU ES"
   EndIf
   If _lTdOK
      aCabec   := {}
      SA2->(DbSetOrder(1))
      SA2->(DbSeek(xFilial("SA2")+aJson[13]))
      _cCondPg := If(Empty(SA2->A2_COND),"001",SA2->A2_COND)
      If aJson[19] == "S" //NF de Complemento
         aadd(aCabec,{"F1_TIPO"   ,"S"        ,Nil,Nil})
         aadd(aCabec,{"F1_TPCOMPL","1"        ,Nil,Nil})
      Else
         aadd(aCabec,{"F1_TIPO"   ,"N"        ,Nil,Nil})
      EndIf
      aadd(aCabec,{"F1_FORMUL" ,"S"        ,Nil,Nil})
      aadd(aCabec,{"F1_DOC"    ,_cNumNF    ,Nil,Nil})
      aadd(aCabec,{"F1_SERIE"  ,_cSerie    ,Nil,Nil})
      aadd(aCabec,{"F1_EMISSAO",dDataBase  ,Nil,Nil})
      aadd(aCabec,{"F1_FORNECE",SubsTr(aJson[13],1,6) ,Nil,Nil})
      aadd(aCabec,{"F1_LOJA"   ,SubsTr(aJson[13],7,2) ,Nil,Nil})
      aadd(aCabec,{"F1_COND"   ,_cCondPg   ,Nil,Nil})
      aadd(aCabec,{"F1_ESPECIE","SPED"     ,Nil,Nil})
      aadd(aCabec,{"F1_XORPIMS","071M"     ,Nil,Nil})
      aadd(aCabec,{"F1_XIDPIMS",AllTrim(Str(aJson[01])) ,Nil,Nil})
      //aadd(aCabec,{"F1_MENNOTA","DATA REF.: "+AllTrim(aJson[10]) ,Nil,Nil}) //Retirado e colocado o abaixo, após solicitação do Divaldo por e-mail em 05/08/2020
      aadd(aCabec,{"F1_MENNOTA",AllTrim(aJson[18]) ,Nil,Nil})
      
      aItAux := {}
      For _nI := 1 To Len(aJSon[34])
         aLinha := {}
         AAdd(aLinha,{"D1_COD"     ,aJSon[34][_nI]:COL004C ,Nil,Nil})
         AAdd(aLinha,{"D1_QUANT"   ,aJSon[34][_nI]:COL006N ,Nil,Nil})
         AAdd(aLinha,{"D1_VUNIT"   ,aJSon[34][_nI]:COL007N,Nil,Nil})
         AAdd(aLinha,{"D1_TOTAL"   ,aJSon[34][_nI]:COL008N,Nil,Nil})
         If AllTrim(aJson[06])=="1" //NF Diária
            AAdd(aLinha,{"D1_TES"     ,_cTES,Nil,Nil})
         EndIf
         If aJson[19] == "S" //NF de Complemento
            AAdd(aLinha,{"D1_NFORI"   ,AllTrim(aJSon[21]) ,Nil,Nil})
            AAdd(aLinha,{"D1_SERIORI" ,_cSerie ,Nil,Nil})
            AAdd(aLinha,{"D1_ITEMORI" ,"0001"  ,Nil,Nil})
         EndIf
         aadd(aItens,aLinha)
      Next _nI

      SB1->( dbSetOrder(1) )
      SA2->( dbSetOrder(1) )

      lMSHelpAuto := .F.
      lMsErroAuto := .F.

      nModulo := 2  //COMPRAS
      If AllTrim(aJson[06])=="1" //NF Diária
         MSExecAuto({|x,y,z|Mata103(x,y,z)},aCabec,aItens,3)
      Else
         MSExecAuto({|x,y,z|Mata140(x,y,z)},aCabec,aItens,3)
      EndIf

      If lMsErroAuto
         //MostraErro()
         conOut(OemToAnsi("071M - ERRO NA INCLUSAO DA NF"))
         /*
         cFileLog := NomeAutoLog()
         cPath    := ""
         cError   := MostraErro(cPath,cFileLog)
         conOut("MostraErro: "+cError)
         */
         aErroAuto := GetAutoGRLog()
         For nCount := 1 To Len(aErroAuto)
            cError := StrTran(StrTran(aErroAuto[nCount], "<", ""), "-", "") + " " //+ enter
            ConOut(cError)
            _cRetErr += cError
         Next nCount
         //cLogErro := TrataErro(MostraErro()) // –> Trata o erro para devolver para o client.
         //ConOut(cLogErro)

         ::cRet := "Erro na busca de registro"
         ::setResponse('{' + enter) 
         ::setResponse( '"col001n": '+AllTrim(Str(aJSon[01]))+',' + enter)
         ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
         ::setResponse( '"col003n": '+AllTrim(Str(aJSon[03]))+',' + enter)
         ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
         ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
         ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
         ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
         ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
         ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
         ::setResponse( '"col010d": "'+aJSon[10]+'",' + enter)
         ::setResponse( '"col011c": "'+aJSon[11]+'",' + enter)
         ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
         ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
         ::setResponse( '"col014c": "'+aJSon[14]+'",' + enter)
         ::setResponse( '"col015c": "'+aJSon[15]+'",' + enter)
         ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
         ::setResponse( '"col017c": "'+aJSon[17]+'",' + enter)
         ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
         ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
         ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
         ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
         ::setResponse( '"col022n": '+AllTrim(Str(aJSon[22]))+',' + enter)
         ::setResponse( '"col023d": "'+aJSon[23]+'",' + enter)
         ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
         ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
         ::setResponse( '"col026c": "'+aJSon[26]+'",' + enter)
         ::setResponse( '"col027c": "'+aJSon[27]+'",' + enter)
         ::setResponse( '"col028d": "'+aJSon[28]+'",' + enter)
         ::setResponse( '"col029d": "'+aJSon[29]+'",' + enter)
         ::setResponse( '"col030c": "'+aJSon[30]+'",' + enter)
         ::setResponse( '"col031c": "'+aJSon[31]+'",' + enter)
         ::setResponse( '"col032c": "'+_cRetErr+'",' + enter)
         ::setResponse( '"col033c": "'+aJSon[31]+'"' + enter)
         ::setResponse('}' + enter)
         DisarmTransaction()
         break
      Else
         SX5->(DbSetOrder(1))
         If SX5->(DbSeek(cFilAnt+"01"+_cSerie))
            _cNovNF := Soma1(_cNumNF)
            If Alltrim(SX5->X5_DESCRI) # _cNovNF
               If RecLock("SX5",.F.)
                  SX5->X5_DESCRI  := _cNovNF
                  SX5->X5_DESCSPA := _cNovNF
                  SX5->X5_DESCENG := _cNovNF
               EndIf
               conOut(OemToAnsi("071M - NUMERAÇÃO NO SX5 NÃO INCREMENTOU AUTOMATICAMENTE PARA "+_cNovNF+"."))
            EndIf
         EndIf
         conOut(OemToAnsi("071M - INCLUSAO DE NF "+_cNumNF+" DE SERIE "+_cSerie+" REALIZADA COM SUCESSO"))

         ::cRet := "Incluscao realizada com sucesso: " + _cNumNF
         
         ::setResponse('{' + enter) 
         ::setResponse( '"col001n": '+AllTrim(Str(aJSon[01]))+',' + enter)
         ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
         ::setResponse( '"col003n": '+AllTrim(Str(aJSon[03]))+',' + enter)
         ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
         ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
         ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
         ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
         ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
         ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
         ::setResponse( '"col010d": "'+aJSon[10]+'",' + enter)
         ::setResponse( '"col011c": "'+aJSon[11]+'",' + enter)
         ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
         ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
         ::setResponse( '"col014c": "'+aJSon[14]+'",' + enter)
         ::setResponse( '"col015c": "'+aJSon[15]+'",' + enter)
         ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
         ::setResponse( '"col017c": "'+aJSon[17]+'",' + enter)
         ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
         ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
         ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
         ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
         ::setResponse( '"col022n": '+AllTrim(Str(aJSon[22]))+',' + enter)
         ::setResponse( '"col023d": "'+aJSon[23]+'",' + enter)
         ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
         ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
         ::setResponse( '"col026c": "'+aJSon[26]+'",' + enter)
         ::setResponse( '"col027c": "IT",' + enter)
         ::setResponse( '"col028d": "'+aJSon[28]+'",' + enter)
         ::setResponse( '"col029d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
         ::setResponse( '"col030c": "'+_cNumNF+'",' + enter)
         ::setResponse( '"col031c": "'+_cSerie+'",' + enter)
         ::setResponse( '"col032c": "INCLUSAO REALIZADA COM SUCESSO",' + enter)
         ::setResponse( '"col033c": "'+aJSon[31]+'"' + enter)
         ::setResponse('}' + enter)
      EndIf
   Else
      conOut(enter + oemToAnsi("Erro na busca de registro! ") + enter)

      ::cRet := "Erro na busca de registro"
      ::setResponse('{' + enter) 
      ::setResponse( '"col001n": '+AllTrim(Str(aJSon[01]))+',' + enter)
      ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
      ::setResponse( '"col003n": '+AllTrim(Str(aJSon[03]))+',' + enter)
      ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
      ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
      ::setResponse( '"col006c": "'+aJSon[06]+'",' + enter)
      ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
      ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
      ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
      ::setResponse( '"col010d": "'+aJSon[10]+'",' + enter)
      ::setResponse( '"col011c": "'+aJSon[11]+'",' + enter)
      ::setResponse( '"col012n": '+Str(aJSon[12])+',' + enter)
      ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
      ::setResponse( '"col014c": "'+aJSon[14]+'",' + enter)
      ::setResponse( '"col015c": "'+aJSon[15]+'",' + enter)
      ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
      ::setResponse( '"col017c": "'+aJSon[17]+'",' + enter)
      ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
      ::setResponse( '"col019c": "'+aJSon[19]+'",' + enter)
      ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
      ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
      ::setResponse( '"col022n": '+AllTrim(Str(aJSon[22]))+',' + enter)
      ::setResponse( '"col023d": "'+aJSon[23]+'",' + enter)
      ::setResponse( '"col024c": "'+aJSon[24]+'",' + enter)
      ::setResponse( '"col025c": "'+aJSon[25]+'",' + enter)
      ::setResponse( '"col026c": "'+aJSon[26]+'",' + enter)
      ::setResponse( '"col027c": "'+aJSon[27]+'",' + enter)
      ::setResponse( '"col028d": "'+aJSon[28]+'",' + enter)
      ::setResponse( '"col029d": "'+aJSon[29]+'",' + enter)
      ::setResponse( '"col030c": "'+aJSon[30]+'",' + enter)
      ::setResponse( '"col031c": "'+aJSon[31]+'",' + enter)
      ::setResponse( '"col032c": "'+_cRetErr+'",' + enter)
      ::setResponse( '"col033c": "'+aJSon[31]+'"' + enter)
      ::setResponse('}' + enter)
   EndIf

END TRANSACTION

RpcClearEnv()

Return .t.



User Function Tstmat261

Local aAuto         := {}
Local aItem         := {}
Local aLinha        := {}
Local _nX           := 1
Local nOpcAuto      := 3

Private lMsErroAuto := .F.
Private lMsErroHelp := .T.

//Cabecalho a Incluir
cDocumen := GetSxeNum("SD3","D3_DOC")
aadd(aAuto,{cDocumen,dDataBase}) //Cabecalho

DbSelectArea("SB1")
SB1->(DbSetOrder(1))
SB1->(DbSeek(xFilial("SB1")+Padr("10000249",TamSx3("B1_COD")[1])))

aLinha := {}
//Origem 
aadd(aLinha,{"ITEM"      ,'00'+cvaltochar(_nX), Nil})
aadd(aLinha,{"D3_COD"    , SB1->B1_COD        , Nil}) //Cod Produto origem 
aadd(aLinha,{"D3_DESCRI" , SB1->B1_DESC       , Nil}) //descr produto origem 
aadd(aLinha,{"D3_UM"     , SB1->B1_UM         , Nil}) //unidade medida origem 
aadd(aLinha,{"D3_LOCAL"  , "01"               , Nil}) //armazem origem 
aadd(aLinha,{"D3_LOCALIZ", ""                 , Nil}) //Informar endereço origem

//Destino 
aadd(aLinha,{"D3_COD"    , SB1->B1_COD , Nil}) //cod produto destino 
aadd(aLinha,{"D3_DESCRI" , SB1->B1_DESC, Nil}) //descr produto destino 
aadd(aLinha,{"D3_UM"     , SB1->B1_UM  , Nil}) //unidade medida destino 
aadd(aLinha,{"D3_LOCAL"  , "02"        , Nil}) //armazem destino 
aadd(aLinha,{"D3_LOCALIZ", ""          , Nil}) //Informar endereço destino

aadd(aLinha,{"D3_NUMSERI", ""       , Nil}) //Numero serie
aadd(aLinha,{"D3_LOTECTL", ""       , Nil}) //Lote Origem
aadd(aLinha,{"D3_NUMLOTE", ""       , Nil}) //sublote origem
aadd(aLinha,{"D3_DTVALID", ''       , Nil}) //data validade 
aadd(aLinha,{"D3_POTENCI", 0        , Nil}) // Potencia
aadd(aLinha,{"D3_QUANT"  , 3        , Nil}) //Quantidade
aadd(aLinha,{"D3_QTSEGUM", 0        , Nil}) //Seg unidade medida
aadd(aLinha,{"D3_ESTORNO", ""       , Nil}) //Estorno 
aadd(aLinha,{"D3_NUMSEQ" , ""       , Nil}) // Numero sequencia D3_NUMSEQ

aadd(aLinha,{"D3_LOTECTL", ""       , Nil}) //Lote destino
aadd(aLinha,{"D3_NUMLOTE", ""       , Nil}) //sublote destino 
aadd(aLinha,{"D3_DTVALID", ''       , Nil}) //validade lote destino
aadd(aLinha,{"D3_ITEMGRD", ""       , Nil}) //Item Grade

aadd(aLinha,{"D3_CODLAN", ""        , Nil}) //cat83 prod origem
aadd(aLinha,{"D3_CODLAN", ""        , Nil}) //cat83 prod destino 

aAdd(aAuto,aLinha)

MSExecAuto({|x,y| mata261(x,y)},aAuto,nOpcAuto)

If lMsErroAuto 
   conOut(OemToAnsi("Erro na inclusao"))
   MostraErro()
Else
   MsgInfo("Inclusão realizada com sucesso!!!")
EndIf

Return

/*/{Protheus.doc} ValInfo
Valida a informação passada, se é C, N ou U (null) - retornando o tipo que deveria ser
@author Max Ivan
@since 27/09/19
@version P12
@uso MP12
@type function
/*/
Static Function ValInfo(_cInfo,_cTipo)

Local _cRet := ""

If     ValType(_cInfo) == "U"
   If _cTipo == "C"
      _cRet := ""
   Else
      _cRet := 0
   EndIf
ElseIf ValType(_cInfo) # _cTipo
   If _cTipo == "C"
      _cRet := AllTrim(Str(_cInfo))
   Else
      _cRet := Val(_cInfo)
   EndIf
Else
   _cRet := _cInfo
EndIf

Return(_cRet)

User Function Tstmat120

Local aCabec  := {}
Local aItens  := {}
Local aLinha  := {}
Local aItemCC := {}
Local aRatCC  := {}
Local nX      := 0
Local nY      := 0
Local cDoc    := ""
Local lOk     := .T.

Private lMsErroAuto := .F.
Private lMsErroHelp := .T.

nSaveSx8 := GetSx8Len()
cDocumen := GetSx8Num('SC7','C7_NUM')

DbSelectArea('SC7')
SC7->(DbSetOrder(1))
While SC7->( DbSeek(xFilial('SC7')+cDocumen))
   ConfirmSx8()
   cDocumen := GetSx8Num('SC7','C7_NUM')
EndDo

DbSelectArea("SA2")
SA2->(DbSetOrder(1))
If SA2->(DbSeek(xFilial("SA2")+"00083901"))
   DbSelectArea("SB1")
   SB1->(DbSetOrder(1))
   If SB1->(DbSeek(xFilial("SB1")+Padr("40000122",TamSx3("B1_COD")[1])))
      aCabec := {}
      aItens := {}

      aadd(aCabec,{"C7_NUM"     ,cDocumen})
      aadd(aCabec,{"C7_EMISSAO" ,dDataBase})
      aadd(aCabec,{"C7_FORNECE" ,SA2->A2_COD})
      aadd(aCabec,{"C7_LOJA"    ,SA2->A2_LOJA})
      aadd(aCabec,{"C7_COND"    ,SA2->A2_COND})
      aadd(aCabec,{"C7_CONTATO" ,"PIMS"})
      aadd(aCabec,{"C7_FILENT"  ,cFilAnt})

      aLinha := {}
      aadd(aLinha,{"C7_PRODUTO" ,SB1->B1_COD,Nil})
      aadd(aLinha,{"C7_QUANT"   ,1          ,Nil})
      aadd(aLinha,{"C7_PRECO"   ,1058       ,Nil})
      aadd(aLinha,{"C7_TOTAL"   ,1058       ,Nil})
      //aadd(aLinha,{"C7_TES"     ,SB1->B1_TE ,Nil})
      aadd(aLinha,{"C7_XCODAPL" ,"03"       ,Nil})
      aadd(aLinha,{"C7_DATPRF"  ,CtoD("01/10/2019"),Nil})
      //aadd(aLinha,{"C7_USER"    ,"000113"   ,Nil})
      aadd(aLinha,{"C7_APROV"   ,"000006"   ,Nil})
      //aadd(aLinha,{"C7_GRUPCOM" ,""       ,Nil})
      aadd(aLinha,{"C7_XIDPIMS" ,"123456",Nil})
      aadd(aItens,aLinha)

      MSExecAuto({|v,x,y,z| MATA120(v,x,y,z)},1,aCabec,aItens,3)
      //MATA120(1,aCabec,aItens,3,,aRatCC)

      If lMsErroAuto 
         If !__lSX8
            RollBackSx8()
         EndIf
         Alert("Erro na inclusao")
         MostraErro()
         lInclui := .F.
         DisarmTransaction()
         break
      Else
         While ( GetSx8Len() > nSaveSx8 )
            ConfirmSx8()
         EndDo
         MsgInfo("Incluido com sucesso! "+ cDocumen)
      EndIf
   Else
      Alert("Produco nao localizado")
   EndIf
Else
   Alert("Fornecedor nao localizado")
EndIf

Return

User Function TstEmat105

Local lRet := .T.
Local aCab := {}
Local aItens := {}
Local nSaveSx8 := 0
Local cNumero := ''

Local nOpcx := 0

Private lMsErroAuto := .F.
Private lMsErroHelp := .T.

//---------- nOpcx = 5 Exclusão de Solicitação de Armazém --------------
nOpcx := 4
Aadd( aCab, { "CP_NUM"     ,"006269" , Nil })
//Aadd( aCab, { "CP_EMISSAO" ,dDataBase , Nil })

Aadd( aItens, {} )
Aadd( aItens[ Len( aItens ) ],{"CP_ITEM"    ,'02' , Nil } )
//Aadd( aItens[ Len( aItens ) ],{"CP_PRODUTO" ,'30000013' , Nil } )
//Aadd( aItens[ Len( aItens ) ],{"CP_QUANT"   ,30 , Nil } )
Aadd( aItens[ Len( aItens ) ],{"AUTDELETA"  ,'S' , Nil } )

//----------------------------------------------------------------------

SB1->( dbSetOrder( 1 ) )
SCP->( dbSetOrder( 1 ) )
MsExecAuto( { | x, y, z | Mata105( x, y , z ) }, aCab, aItens , nOpcx )

If lMsErroAuto
   MsgStop( 'Erro ao Executar o Processo' )
   MostraErro()
   lRet := .F.
Else
   MsgInfo( 'Processo Executado' )
EndIf

Return

User Function Tstmat185E

Local aCamposSCP
Local aCamposSD3

Local aRelProj
Local cNum   := "006269" // No.da Requisicao
Local cItem  := "05" // No.do Item da Req.
LOCAL aRetCQ := {}

DbSelectArea("SCP")
DbSetOrder(1)
If SCP->(dbSeek(xFilial("SCP")+cNum+cItem))
   aCamposSCP := { {"CP_NUM" ,SCP->CP_NUM ,Nil },;
                   {"CP_ITEM" ,SCP->CP_ITEM ,Nil },;
                   {"CP_QUANT" ,SCP->CP_QUANT ,Nil }}

   aCamposSD3 := { {"D3_TM" ,"501" ,Nil },; // Tipo do Mov.
                   {"D3_COD" ,SCP->CP_PRODUTO,Nil },;
                   {"D3_LOCAL" ,SCP->CP_LOCAL ,Nil },;
                   {"D3_DOC" ,"" ,Nil },; // No.do Docto.
                   {"D3_EMISSAO" ,DDATABASE ,Nil }}

   aRelProj := {}

   lMSHelpAuto := .F.
   lMsErroAuto := .F.

   MSExecAuto({|v,x,y,z,w| mata185(v,x,y,z,w)},aCamposSCP,aCamposSD3,2,,aRelProj)   // 1 = BAIXA (ROT.AUT)

   If lMsErroAuto
      MostraErro()
   Else
      MsgInfo("Estorno com sucesso!!!")
   EndIF

EndIf

Return Nil

User Function TstMta115

Local lInclui       := .T.

Local aDadoscab     := {}
Local aDadosIte     := {}
Local aItens        := {}
 
Private oModel      := Nil
Private lMsErroAuto := .F.

oModel  := FwLoadModel ("MATA311")

aRotina := {}

DbSelectArea("SB1")
SB1->(DbSetOrder(1))
If SB1->(DbSeek(xFilial("SB1")+Padr("10000002",TamSx3("B1_COD")[1])))
   _cAlmOri := "01"

  //Adicionando os dados do ExecAuto cab
  nSaveSx8 := GetSx8Len()
  cDocumen := GetSx8Num("NNS","NNS_COD")

  NNS->(DbSetOrder(1))
  While NNS->(DbSeek(xFilial('NNS')+cDocumen))
     ConfirmSx8()
     cDocumen := GetSx8Num("NNS","NNS_COD")
  EndDo

  aAdd(aDadoscab, {"NNS_FILIAL", xFilial("NNS")                , Nil})
  aAdd(aDadoscab, {"NNS_COD"   , cDocumen                      , Nil})
  aAdd(aDadoscab, {"NNS_DATA"  , CTOD("17/10/2019") , Nil})
  aAdd(aDadoscab, {"NNS_SOLICT", '000000'                      , Nil})
  aAdd(aDadoscab, {"NNS_CLASS" , '1'                           , Nil})
  aAdd(aDadoscab, {"NNS_ESPECI", ' '                           , Nil})

  //Adicionando os dados do ExecAuto Item
  aAdd(aDadosIte, {"NNT_FILIAL" , xFilial("NNT") , Nil})
  aAdd(aDadosIte, {"NNT_FILORI" , xFilial("NNT") , Nil})
  aAdd(aDadosIte, {"NNT_PROD"   , SB1->B1_COD    , Nil})
  aAdd(aDadosIte, {"NNT_LOCAL"  , _cAlmOri       , Nil})
  //aAdd(aDadosIte, {"NNT_LOCALI" , 'AA1' , Nil})
  aAdd(aDadosIte, {"NNT_QUANT"  , 10             , Nil})
  aAdd(aDadosIte, {"NNT_FILDES" , xFilial("NNT") , Nil})
  aAdd(aDadosIte, {"NNT_PRODD"  , SB1->B1_COD    , Nil})
  aAdd(aDadosIte, {"NNT_LOCLD"  , "90"           , Nil})
  aAdd(aDadosIte, {"NNT_XIDPIM" , AllTrim(Str(1)) , Nil})
  aAdd(aDadosIte, {"NNT_XOSPIM" , AllTrim(Str(6849)) , Nil})

  //no item o array precisa de um nivel superior.
  aAdd(aItens,aDadosIte)

  //Chamando a inclusão - Modelo 1
  lMsErroAuto := .F.

  FWMVCRotAuto( oModel,"NNS",3,{{"NNSMASTER", aDadoscab},{"NNTDETAIL", aItens}})

  //Se houve erro no ExecAuto, mostra mensagem
  If lMsErroAuto
     MostraErro()
     If !__lSX8
        RollBackSx8()
     EndIf
  Else
     MsgInfo("Registro incluido!", "Atenção")
     While ( GetSx8Len() > nSaveSx8 )
        ConfirmSx8()
     EndDo
  EndIf
EndIf

Return

Static Function IncSB9(_cProd,_cAlmox,_nQtde)

//Setando valores da rotina automática
lMsErroAuto := .F.        
aVetor :={;
    {"B9_FILIAL", FWxFilial('SB9'), Nil},;
    {"B9_COD",    _cProd,           Nil},;
    {"B9_LOCAL",  _cAlmox,          Nil},;
    {"B9_QINI",   _nQtde,           Nil};
}
 
//Iniciando transação e executando saldos iniciais
MSExecAuto({|x, y| Mata220(x, y)}, aVetor, 3)
     
Return

/*/{Protheus.doc} PIMS163M
Serviço POST para inclusão de Produção
@author Max Ivan
@since 30/04/21
@version P12
@uso MP12
@type function
/*/
WSRESTFUL INT_PIMS_163M DESCRIPTION "Servico REST para Inclusao de Producao"

//COLOCAR CAMPOS OBRIGATORIOS ABAIXO
WSDATA cRet		AS STRING

WSMETHOD POST DESCRIPTION "POST / Servico REST para Inclusao de Producao" WSSYNTAX ""

END WSRESTFUL

WSMETHOD POST WSRECEIVE RECEIVE WSSERVICE INT_PIMS_163M

Local aJSon         := {}
Local aLog		     := {}
Local cJson         := ::getContent()
Local cUniEmp		  := ""
Local cFilEmp		  := ""
Local lInclui       := .T.
Local _lOk          := .T.
Local _cMensRej     := ""
Local nCount        := 1

Local aDadoscab     := {}
Local aDadosIte     := {}
Local aItens        := {}
 
Private oModel         := Nil
Private lMsErroAuto    := .F.
Private lMsErroHelp    := .T.
Private lAutoErrNoFile := .T.

oParseJSON := nil

::setContentType("application/json")
FWJsonDeserialize(DecodeUtf8(cJson), @oParseJSON)

conOut(enter + oemToAnsi("163M - INICIO - ANTES CARREGAR EMPRESAS: ") + enter)

If ValType(oParseJSON) == "A" //json com mais de 1 linha
   cUniEmp := oParseJSON[1]:col003c
   cFilEmp := oParseJSON[1]:col004c
Else
   cUniEmp := oParseJSON:col003c
   cFilEmp := oParseJSON:col004c
EndIf

//cUserName := LogUserName()
//ALTEMP(cUniEmp,cFilEmp)

RpcSetType(3)
RpcSetEnv(cUniEmp,cFilEmp,"","","EST")
cEmpAnt := cUniEmp
cFilAnt := cFilEmp

BEGIN TRANSACTION  

If ValType(oParseJSON) == "A" //json com mais de 1 linha
   _nIJson   := 1
   _nTamJson := Len(oParseJSON)
   While _nIJson <= _nTamJson
      aJSon := {}
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL001N,"N")) //Sequencia exclusiva (PK)
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL002C,"C")) //Codigo da empresa no PIMS-PI
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL003C,"C")) //Codigo ERP da empresa
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL004C,"C")) //Codigo ERP da filial
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL005C,"C")) //Codigo da OP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL006D,"C")) //Data da produção
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL007C,"C")) //Codigo ERP do produto final - Produto chave para busca da ordem de produção
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL008C,"C")) //Codigo PIMS-PI da variavel
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL009C,"C")) //Descrição PIMS-PI da variavel
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL010N,"N")) //Quantidade produzida no dia
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL011N,"N")) //Quantidade acumulada na safra
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL012C,"C")) //Codigo ERP da unidade de medida
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL013C,"C")) //Tipo do movimento para o item
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL014D,"C")) //Data e hora do envio pelo PIMS
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL015D,"C")) //Data e hora da integração pelo ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL016C,"C")) //Numero do documento gerado no ERP
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL017C,"C")) //Situação do registro... 01,02,...08
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL018C,"C")) //Tipo de Movimento; S=Estorno e N=Normal (Movimento)
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL019C,"C")) //Mensagem de Integração
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL020C,"C")) //Estornado SIM, ou Não
      AAdd(aJSon,ValInfo(oParseJSON[_nIJson]:COL021C,"C")) //Centro de Custo
      /*Exemplo de envio de POST
      {
         "col001n": 1,
         "col002c": "001",
         "col003c": "01",
         "col004c": "0101",
         "col005c": "OP1",
         "col006d": "31/08/2021",
         "col007c": "28997",
         "col008c": "ALCOOLPROD",
         "col009c": "PRODUÇÃO ETANOL - TESTE",
         "col010n": 190058,
         "col011n": 15976457,
         "col012c": "L",
         "col013c": "P",
         "col014d": "31/05/2022 00:00:00",
         "col015d": null,
         "col016c": null,
         "col017c": "0",
         "col018c": "N",
         "col019c": "Erro - Invalid mime type \"charset=utf-8\": does not contain '/'",
         "col020c": "N"
      */

      conOut(enter + oemToAnsi("163M - Filial em Execucao: ") + cFilAnt + enter)

      SD3->(DbOrderNickName("XIDPIMSPRD"))
      If !SD3->(DbSeek(xFilial("SD3")+"163M"+AllTrim(Str(aJSon[01]))))
         _cMensRej := ""
         SB1->(DbSetOrder(1))
         If !SB1->(DbSeek(xFilial("SB1")+aJSon[07]))
            _cMensRej += "(163M) Produto (col007c) nao localizado - "
            _lOk      := .F.
         EndIf
         CTT->(DbSetOrder(1))
         If !Empty(aJSon[21]) .and. !CTT->(DbSeek(xFilial("CTT")+aJSon[21]))
            _cMensRej += "(163M) Centro de Custo (col021c) nao localizado - "
            _lOk      := .F.
         EndIf
         SC2->(DbSetOrder(2))
         If SC2->(DbSeek(xFilial("SC2")+PadR(aJSon[07],TamSX3("C2_PRODUTO")[1])))
            /*
            If SC2->C2_QUANT-SC2->C2_QUJE < aJSon[10]
               _cMensRej += "OP "+SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN+" nao possui saldo suficiente para atendimento - "
               _lOk      := .F.
            EndIf
            */
            While SC2->(!Eof()) .and. PadR(aJSon[07],TamSX3("C2_PRODUTO")[1]) == SC2->C2_PRODUTO .and. (SC2->C2_QUANT-SC2->C2_QUJE < aJSon[10] .or. SC2->C2_STATUS == "U")
               SC2->(DbSkip())
            EndDo
            If SC2->(Eof()) .or. PadR(aJSon[07],TamSX3("C2_PRODUTO")[1]) # SC2->C2_PRODUTO .or. SC2->C2_QUANT-SC2->C2_QUJE < aJSon[10]
               //SetRestFault( 404, EncodeUTF8("Nao existe OP em aberto para o Produto"))
               //Return lOK
               _cMensRej += "Nao existe OP em aberto para o Produto, com saldo suficiente para o atendimento"
               _lOk      := .F.
            EndIf
         Else
            _cMensRej += "Nao localizado OP para o Produto - "
            _lOk      := .F.
         EndIf
         
         If _lOk //Ok para Produção / Materia prima
            nOpc  := 3 //-Opção de execução da rotina
            dData := Date()

            aVetor := { {"D3_OP"     ,SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN,NIL},;
                        {"D3_COD"    ,SC2->C2_PRODUTO                        ,NIL},;
                        {"D3_QUANT"  ,aJSon[10]                              ,NIL},;
                        {"ATUEMP"    , "T"                                   ,NIL},;
                        {"D3_TM"     ,GetNewPar("NX_TM163M","199")           ,NIL}}

            lMSHelpAuto := .F.
            lMsErroAuto := .F.
   
            MSExecAuto({|x, y| mata250(x, y)},aVetor, nOpc )
   
            //Se houve erro no ExecAuto, mostra mensagem
            If lMsErroAuto

               _cRetErr := ""
               conOut(OemToAnsi("163M - (PRODUCAO) ERRO EXECAUTO"))
               aErroAuto := GetAutoGRLog()
               For nCount := 1 To Len(aErroAuto)
                  cLogErro := StrTran(StrTran(aErroAuto[nCount], "<", ""), "-", "") + " " //+ enter
                  ConOut(cLogErro)
                  _cRetErr += cLogErro
               Next nCount
               _cRetErr := EncodeUTF8(_cRetErr, "cp1252")

               ::cRet := "ERRO: " + _cRetErr + enter
               ::setResponse('{' + enter) 
               ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
               ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
               ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
               ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
               ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
               ::setResponse( '"col006d": "'+aJSon[06]+'",' + enter)
               ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
               ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
               ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
               ::setResponse( '"col010n": '+Str(aJSon[10])+',' + enter)
               ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
               ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
               ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
               ::setResponse( '"col014d": "'+aJSon[14]+'",' + enter)
               ::setResponse( '"col015d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
               ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
               ::setResponse( '"col017c": "0",' + enter)
               ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
               ::setResponse( '"col019c": "'+Substr(_cRetErr,1,2000)+'",' + enter)
               ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
               ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
               ::setResponse('}' + enter)
               DisarmTransaction()
               break

            Else
               If RecLock("SD3",.F.)
                  SD3->D3_XIDPIMS := AllTrim(Str(aJSon[01]))
                  SD3->D3_XORPIMS := "163M"
                  SD3->(MsUnLock())
               EndIf
               conOut(enter + oemToAnsi("Incluido com sucesso! ") + SD3->D3_DOC + enter)
               ::cRet := "Incluido com sucesso : Codigo: " + SD3->D3_DOC
               ::setResponse('{' + enter) 
               ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
               ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
               ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
               ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
               ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
               ::setResponse( '"col006d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
               ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
               ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
               ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
               ::setResponse( '"col010n": '+Str(aJSon[10])+',' + enter)
               ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
               ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
               ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
               ::setResponse( '"col014d": "'+aJSon[14]+'",' + enter)
               ::setResponse( '"col015d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
               ::setResponse( '"col016c": "'+AllTrim(SD3->D3_DOC)+'",' + enter)
               ::setResponse( '"col017c": "2",' + enter)
               ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
               ::setResponse( '"col019c": "PRODUCAO REALIZADA COM SUCESSO",' + enter)
               ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
               ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
               ::setResponse('}' + enter)
            EndIf
         Else
            conOut(OemToAnsi(_cMensRej))
            ::cRet := _cMensRej
            ::setResponse('{' + enter) 
            ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
            ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
            ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
            ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
            ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
            ::setResponse( '"col006d": "'+aJSon[06]+'",' + enter)
            ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
            ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
            ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
            ::setResponse( '"col010n": '+Str(aJSon[10])+',' + enter)
            ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
            ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
            ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
            ::setResponse( '"col014d": "'+aJSon[14]+'",' + enter)
            ::setResponse( '"col015d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
            ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
            ::setResponse( '"col017c": "0",' + enter)
            ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
            ::setResponse( '"col019c": "'+_cMensRej+'",' + enter)
            ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
            ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
            ::setResponse('}' + enter)
         EndIf
      Else
         //Produto nao localizado
         conOut(OemToAnsi("OP ja existente"))
         ::cRet := "OP JA EXISTENTE"
         ::setResponse('{' + enter) 
         ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
         ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
         ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
         ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
         ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
         ::setResponse( '"col006d": "'+aJSon[06]+'",' + enter)
         ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
         ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
         ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
         ::setResponse( '"col010n": '+Str(aJSon[10])+',' + enter)
         ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
         ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
         ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
         ::setResponse( '"col014d": "'+aJSon[14]+'",' + enter)
         ::setResponse( '"col015d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
         ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
         ::setResponse( '"col017c": "0",' + enter)
         ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
         ::setResponse( '"col019c": "'+_cMensRej+'",' + enter)
         ::setResponse( '"col020c": "OP JA EXISTENTE",' + enter)
         ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
         ::setResponse('}' + enter)
      EndIf
      /*
      If _nIJson == _nTamJson
         _cRetJson := _cRetJson + ']' + enter
      EndIf
      */
      _nIJson++
   EndDo
Else
   AAdd(aJSon,ValInfo(oParseJSON:COL001N,"N")) //Sequencia exclusiva (PK)
   AAdd(aJSon,ValInfo(oParseJSON:COL002C,"C")) //Codigo da empresa no PIMS-PI
   AAdd(aJSon,ValInfo(oParseJSON:COL003C,"C")) //Codigo ERP da empresa
   AAdd(aJSon,ValInfo(oParseJSON:COL004C,"C")) //Codigo ERP da filial
   AAdd(aJSon,ValInfo(oParseJSON:COL005C,"C")) //Codigo da OP
   AAdd(aJSon,ValInfo(oParseJSON:COL006D,"C")) //Data da produção
   AAdd(aJSon,ValInfo(oParseJSON:COL007C,"C")) //Codigo ERP do produto final - Produto chave para busca da ordem de produção
   AAdd(aJSon,ValInfo(oParseJSON:COL008C,"C")) //Codigo PIMS-PI da variavel
   AAdd(aJSon,ValInfo(oParseJSON:COL009C,"C")) //Descrição PIMS-PI da variavel
   AAdd(aJSon,ValInfo(oParseJSON:COL010N,"N")) //Quantidade produzida no dia
   AAdd(aJSon,ValInfo(oParseJSON:COL011N,"N")) //Quantidade acumulada na safra
   AAdd(aJSon,ValInfo(oParseJSON:COL012C,"C")) //Codigo ERP da unidade de medida
   AAdd(aJSon,ValInfo(oParseJSON:COL013C,"C")) //Tipo do movimento para o item
   AAdd(aJSon,ValInfo(oParseJSON:COL014D,"C")) //Data e hora do envio pelo PIMS
   AAdd(aJSon,ValInfo(oParseJSON:COL015D,"C")) //Data e hora da integração pelo ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL016C,"C")) //Numero do documento gerado no ERP
   AAdd(aJSon,ValInfo(oParseJSON:COL017C,"C")) //Situação do registro... 01,02,...08
   AAdd(aJSon,ValInfo(oParseJSON:COL018C,"C")) //Tipo de Movimento; S=Estorno e N=Normal (Movimento)
   AAdd(aJSon,ValInfo(oParseJSON:COL019C,"C")) //Mensagem de Integração
   AAdd(aJSon,ValInfo(oParseJSON:COL020C,"C")) //Estornado SIM, ou Não
   AAdd(aJSon,ValInfo(oParseJSON:COL021C,"C")) //Centro de Custo
   /*Exemplo de envio de POST
   {
      "col001n": 1,
      "col002c": "001",
      "col003c": "01",
      "col004c": "0101",
      "col005c": "OP1",
      "col006d": "31/08/2021",
      "col007c": "28997",
      "col008c": "ALCOOLPROD",
      "col009c": "PRODUÇÃO ETANOL - TESTE",
      "col010n": 190058,
      "col011n": 15976457,
      "col012c": "L",
      "col013c": "P",
      "col014d": "31/05/2022 00:00:00",
      "col015d": null,
      "col016c": null,
      "col017c": "0",
      "col018c": "N",
      "col019c": "Erro - Invalid mime type \"charset=utf-8\": does not contain '/'",
      "col020c": "N"
   */

   conOut(enter + oemToAnsi("163M - Filial em Execucao: ") + cFilAnt + enter)

   SD3->(DbOrderNickName("XIDPIMSPRD"))
   If !SD3->(DbSeek(xFilial("SD3")+"163M"+AllTrim(Str(aJSon[01]))))
      _cMensRej := ""
      SB1->(DbSetOrder(1))
      If !SB1->(DbSeek(xFilial("SB1")+aJSon[07]))
         _cMensRej += "(163M) Produto (col007c) nao localizado - "
         _lOk      := .F.
      EndIf
      CTT->(DbSetOrder(1))
      If !Empty(aJSon[21]) .and. !CTT->(DbSeek(xFilial("CTT")+aJSon[21]))
         _cMensRej += "(163M) Centro de Custo (col021c) nao localizado - "
         _lOk      := .F.
      EndIf
      SC2->(DbSetOrder(2))
      If SC2->(DbSeek(xFilial("SC2")+PadR(aJSon[07],TamSX3("C2_PRODUTO")[1])))
         /*
         If SC2->C2_QUANT-SC2->C2_QUJE < aJSon[10]
            _cMensRej += "OP "+SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN+" nao possui saldo suficiente para atendimento - "
            _lOk      := .F.
         EndIf
         */
         While SC2->(!Eof()) .and. PadR(aJSon[07],TamSX3("C2_PRODUTO")[1]) == SC2->C2_PRODUTO .and. (SC2->C2_QUANT-SC2->C2_QUJE < aJSon[10] .or. SC2->C2_STATUS == "U")
            SC2->(DbSkip())
         EndDo
         If SC2->(Eof()) .or. PadR(aJSon[07],TamSX3("C2_PRODUTO")[1]) # SC2->C2_PRODUTO .or. SC2->C2_QUANT-SC2->C2_QUJE < aJSon[10]
            //SetRestFault( 404, EncodeUTF8("Nao existe OP em aberto para o Produto"))
            //Return lOK
            _cMensRej += "Nao existe OP em aberto para o Produto, com saldo suficiente para o atendimento"
            _lOk      := .F.
         EndIf
      Else
         _cMensRej += "Nao localizado OP para o Produto - "
         _lOk      := .F.
      EndIf
      
      If _lOk //Ok para Produção / Materia prima
         nOpc  := 3 //-Opção de execução da rotina
         dData := Date()

         aVetor := { {"D3_OP"     ,SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN,NIL},;
                     {"D3_COD"    ,SC2->C2_PRODUTO                        ,NIL},;
                     {"D3_QUANT"  ,aJSon[10]                              ,NIL},;
                     {"ATUEMP"    , "T"                                   ,NIL},;
                     {"D3_TM"     ,GetNewPar("NX_TM163M","199")           ,NIL}}

         lMSHelpAuto := .F.
         lMsErroAuto := .F.
   
         MSExecAuto({|x, y| mata250(x, y)},aVetor, nOpc )
   
         //Se houve erro no ExecAuto, mostra mensagem
         If lMsErroAuto

            _cRetErr := ""
            conOut(OemToAnsi("163M - (PRODUCAO) ERRO EXECAUTO"))
            aErroAuto := GetAutoGRLog()
            For nCount := 1 To Len(aErroAuto)
               cLogErro := StrTran(StrTran(aErroAuto[nCount], "<", ""), "-", "") + " " //+ enter
               ConOut(cLogErro)
               _cRetErr += cLogErro
            Next nCount
            _cRetErr := EncodeUTF8(_cRetErr, "cp1252")

            ::cRet := "ERRO: " + _cRetErr + enter
            ::setResponse('{' + enter) 
            ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
            ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
            ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
            ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
            ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
            ::setResponse( '"col006d": "'+aJSon[06]+'",' + enter)
            ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
            ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
            ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
            ::setResponse( '"col010n": '+Str(aJSon[10])+',' + enter)
            ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
            ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
            ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
            ::setResponse( '"col014d": "'+aJSon[14]+'",' + enter)
            ::setResponse( '"col015d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
            ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
            ::setResponse( '"col017c": "0",' + enter)
            ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
            ::setResponse( '"col019c": "'+Substr(_cRetErr,1,2000)+'",' + enter)
            ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
            ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
            ::setResponse('}' + enter)
            DisarmTransaction()
            break

         Else
            If RecLock("SD3",.F.)
               SD3->D3_XIDPIMS := AllTrim(Str(aJSon[01]))
               SD3->D3_XORPIMS := "163M"
               SD3->(MsUnLock())
            EndIf
            conOut(enter + oemToAnsi("Incluido com sucesso! ") + SD3->D3_DOC + enter)
            ::cRet := "Incluido com sucesso : Codigo: " + SD3->D3_DOC
            ::setResponse('{' + enter) 
            ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
            ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
            ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
            ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
            ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
            ::setResponse( '"col006d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
            ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
            ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
            ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
            ::setResponse( '"col010n": '+Str(aJSon[10])+',' + enter)
            ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
            ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
            ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
            ::setResponse( '"col014d": "'+aJSon[14]+'",' + enter)
            ::setResponse( '"col015d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
            ::setResponse( '"col016c": "'+AllTrim(SD3->D3_DOC)+'",' + enter)
            ::setResponse( '"col017c": "2",' + enter)
            ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
            ::setResponse( '"col019c": "PRODUCAO REALIZADA COM SUCESSO",' + enter)
            ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
            ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
            ::setResponse('}' + enter)
         EndIf
      Else
         conOut(OemToAnsi(_cMensRej))
         ::cRet := _cMensRej
         ::setResponse('{' + enter) 
         ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
         ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
         ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
         ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
         ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
         ::setResponse( '"col006d": "'+aJSon[06]+'",' + enter)
         ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
         ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
         ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
         ::setResponse( '"col010n": '+Str(aJSon[10])+',' + enter)
         ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
         ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
         ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
         ::setResponse( '"col014d": "'+aJSon[14]+'",' + enter)
         ::setResponse( '"col015d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
         ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
         ::setResponse( '"col017c": "0",' + enter)
         ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
         ::setResponse( '"col019c": "'+_cMensRej+'",' + enter)
         ::setResponse( '"col020c": "'+aJSon[20]+'",' + enter)
         ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
         ::setResponse('}' + enter)
      EndIf
   Else
      //Produto nao localizado
      conOut(OemToAnsi("OP ja existente"))
      ::cRet := "OP JA EXISTENTE"
      ::setResponse('{' + enter) 
      ::setResponse( '"col001n": '+Str(aJSon[01])+',' + enter)
      ::setResponse( '"col002c": "'+aJSon[02]+'",' + enter)
      ::setResponse( '"col003c": "'+aJSon[03]+'",' + enter)
      ::setResponse( '"col004c": "'+aJSon[04]+'",' + enter)
      ::setResponse( '"col005c": "'+aJSon[05]+'",' + enter)
      ::setResponse( '"col006d": "'+aJSon[06]+'",' + enter)
      ::setResponse( '"col007c": "'+aJSon[07]+'",' + enter)
      ::setResponse( '"col008c": "'+aJSon[08]+'",' + enter)
      ::setResponse( '"col009c": "'+aJSon[09]+'",' + enter)
      ::setResponse( '"col010n": '+Str(aJSon[10])+',' + enter)
      ::setResponse( '"col011n": '+Str(aJSon[11])+',' + enter)
      ::setResponse( '"col012c": "'+aJSon[12]+'",' + enter)
      ::setResponse( '"col013c": "'+aJSon[13]+'",' + enter)
      ::setResponse( '"col014d": "'+aJSon[14]+'",' + enter)
      ::setResponse( '"col015d": "'+StrZero(Day(Date()),2)+"/"+StrZero(Month(Date()),2)+"/"+StrZero(Year(Date()),4)+' '+Time()+'",' + enter)
      ::setResponse( '"col016c": "'+aJSon[16]+'",' + enter)
      ::setResponse( '"col017c": "0",' + enter)
      ::setResponse( '"col018c": "'+aJSon[18]+'",' + enter)
      ::setResponse( '"col019c": "'+_cMensRej+'",' + enter)
      ::setResponse( '"col020c": "OP JA EXISTENTE",' + enter)
      ::setResponse( '"col021c": "'+aJSon[21]+'",' + enter)
      ::setResponse('}' + enter)
   EndIf
EndIf

END TRANSACTION

//RpcClearEnv()

Return .t.

Static Function ALTEMP(cEmp, cFil)

Local cemp:=cEmp
Local cfil:=cFil
	
	dbcloseall()
	cempant :=cemp
	cfilant :=cfil 
	cNumEmp :=cemp+cfil
   nModulo := 4
	Opensm0(cempant+cfil)
 	Openfile(cempant+cfil)
	lrefresh :=.T.
	       
Return

User Function TstABSE1

SE2->(DbSetOrder(1))
If SE2->(DbSeek(SF1->F1_FILIAL+SF1->F1_PREFIXO+SF1->F1_DUPL))
   aVetor := {{"E2_TIPO"	 ,"AB-"                     ,Nil},;
              {"E2_VALOR"   ,776692                    ,Nil},;
              {"E2_HIST"	 ,"ADIANTAMENTO"            ,Nil},;
              {"E2_XORPIMS" ,"061M"                    ,Nil},;
              {"E2_XIDPIMS" ,AllTrim(Str(6560))        ,Nil}}

   MSExecAuto({|x,y| Fina050(x,y)},aVetor,3) //Inclusao de AB-
   If lMsErroAuto
      MostraErro()
   Else
      MsgInfo("Inclusão realizada com sucesso!")
   EndIf
Else
   Alert("Titulo não localizado!")
EndIf

Return
