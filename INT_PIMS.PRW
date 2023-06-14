#INCLUDE "TopConn.ch"
#INCLUDE "Totvs.ch"

#define enter chr(13) + chr(10)

/*/{Protheus.doc}
Funções para integracao do Protheus com PIMS por WS REST / Json
@author Max Ivan (Nexus)
@since 04/08/19
@version P12
@uso ENERSURGAR
@type function
/*/

User Function WCRestJson(cEndpoint,cResource,cJson)

	Local aHeader :=  {}
	Private cHeadRet := ""

	aadd(aHeader,'Content-Type: application/json; charset=utf-8')

	sPostRet := HttpPost(cEndpoint+cResource,,cJson,30,aHeader,@cHeadRet)

Return(sPostRet)

/*/{Protheus.doc}
Ponto de Entrada executado na inclusao e alteracao do Produto, para alimentar o WS do PIMS
@author Max Ivan (Nexus)
@since 04/08/19
@version P12
@uso Enersugar
@type function
/*/
User Function INT_I003C

	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_003c/"
	Local _cResouNNR := "/totvs-1.0/int_pims_008c/"
	Local _cResouSB2 := "/totvs-1.0/int_pims_004c/"
	Local _cJson     := ""
	Local _cRet      := ""
	Local _aArAtu    := GetArea()
	Local _aArSB1    := SB1->(GetArea())

	If SBM->(FieldPos("BM_X_TPIMS")) <= 0
		Return
	EndIf
	//Somente integra com o PIMS se o campo BM_X_TPIMS estiver preenchido
	SBM->(DbSetOrder(1))
	If SBM->(DbSeek(xFilial("SBM")+M->B1_GRUPO)) .and. !Empty(SBM->BM_X_TPIMS)
		//DEPOSITO
		NNR->(DbSetOrder(1))
		NNR->(DbSeek(xFilial("NNR")+M->B1_LOCPAD))
		_cJson := ' { ' +;
		'"col001c": "'+cEmpAnt+'", ' +;
		'"col002c": "'+cFilAnt+'", ' +;
		'"col003c": "'+AllTrim(NNR->NNR_CODIGO)+'", ' +;
		'"col004c": "'+AllTrim(NNR->NNR_DESCRI)+'", ' +;
		'"col005c": "1", ' +;
		'"col006c": "F", ' +;
		'"col007d": "'+DtoC(Date())+' '+Time()+' ", ' +;
		'"col010c": "I"' +;
		'} '
		_cJson := EncodeUTF8(_cJson, "cp1252")
		_cRet := U_WCRestJson(_cEndPoint,_cResouNNR,_cJson)
		If IsBlind()
			Conout("Integração com PIMS - Inclusão Depósito")
			Conout(_cRet)
		Else
			If GetNewPar("NX_AVINTE", "S") == "S"
				MsgInfo(_cRet,"Integração com PIMS - Inclusão Depósito")
				Conout("Integração com PIMS - Inclusão Depósito")
				Conout(_cRet)
			EndIf
		EndIf

		//SALDOS NOS DEPOSITOS
		SB2->(DbSetOrder(1))
		If SB2->(DbSeek(xFilial("SB2")+M->B1_COD))
			While SB2->(!Eof()) .and. xFilial("SB2")+M->B1_COD == SB2->B2_FILIAL+SB2->B2_COD
				_cJson := ' { ' +;
				'"col001c": "'+cEmpAnt+'", ' +;
				'"col002c": "'+cFilAnt+'", ' +;
				'"col003c": "'+AllTrim(M->B1_COD)+'", ' +;
				'"col004c": "'+AllTrim(SB2->B2_LOCAL)+'", ' +;
				'"col005n": '+AllTrim(Str(SB2->B2_QATU))+', ' +;
				'"col006n": '+AllTrim(Str(SB2->B2_CM1))+', ' +;
				'"col007n": '+AllTrim(Str(M->B1_UPRC))+', ' +;
				'"col008c": "1", ' +;
				'"col009c": "'+AllTrim(M->B1_CONTA)+'", ' +;
				'"col010d": "'+If(!Empty(M->B1_UCOM),DtoC(M->B1_UCOM)+' '+Time(),"")+' ", ' +;
				'"col011d": "'+DtoC(Date())+' '+Time()+'", ' +;
				'"col012d": "", ' +;
				'"col013c": "NI", ' +;
				'"col014c": "I"' +;
				'} '
				_cJson := EncodeUTF8(_cJson, "cp1252")
				_cRet := U_WCRestJson(_cEndPoint,_cResouSB2,_cJson)
				If IsBlind()
					Conout("Integração com PIMS - Inclusão Saldo")
					Conout(_cRet)
				Else
					If GetNewPar("NX_AVINTE", "S") == "S"
						MsgInfo(_cRet,"Integração com PIMS - Inclusão Saldo")
						Conout("Integração com PIMS - Inclusão Saldo")
						Conout(_cRet)
					EndIf
				EndIf

				SB2->(DbSkip())
			EndDo
		EndIf

		//PRODUTO
		_cJson := ' { ' +;
		'"col001c": "'+AllTrim(M->B1_COD)+'", ' +;
		'"col002n": "", ' +;
		'"col003c": "'+AllTrim(M->B1_GRUPO)+'", ' +;
		'"col004c": "'+AllTrim(Posicione("SBM",1,xFilial("SBM")+M->B1_GRUPO,"BM_DESC"))+'", ' +;
		'"col005c": "'+AllTrim(M->B1_UM)+'", ' +;
		'"col006c": "'+AllTrim(Posicione("SAH",1,xFilial("SAH")+M->B1_UM,"AH_UMRES"))+'", ' +;
		'"col007c": "'+AllTrim(M->B1_DESC)+'", ' +;
		'"col008c": "'+AllTrim(M->B1_GRUPO)+'", ' +;
		'"col009c": "'+If(M->B1_MSBLQL=="1","0","1")+'", ' +;
		'"col010c": "'+AllTrim(M->B1_CONTA)+'", ' +;
		'"col011c": "1", ' +;
		'"col012c": "M", ' +;
		'"col013n": 1, ' +;
		'"col014c": "'+SBM->BM_X_TPIMS+'", ' +;
		'"col015c": "S", ' +;
		'"col016d": "", ' +;
		'"col017d": "'+DtoC(Date())+' '+Time()+' ", ' +;
		'"col018c": "", ' +;
		'"col019c": "I", ' +;
		'"col020d": "" ' +;
		'} '
		_cJson := EncodeUTF8(_cJson, "cp1252")
		//Alert(_cJson)
		_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
		If IsBlind()
			Conout("Integração com PIMS - Inclusão Produto")
			Conout(_cRet)
		Else
			If GetNewPar("NX_AVINTE", "S") == "S"
				MsgInfo(_cRet,"Integração com PIMS - Inclusão Produto")
				Conout("Integração com PIMS - Inclusão Produto")
				Conout(_cRet)
			EndIf
		EndIf
	EndIf

	RestArea(_aArSB1)
	RestArea(_aArAtu)

Return(.T.)

/*/{Protheus.doc}
Ponto de Entrada executado na inclusão de Fornecedor, para alimentar o WS do PIMS
@author Max Ivan (Nexus)
@since 04/08/19
@version P12
@uso Enersugar
@type function
/*/
User Function INT_I005C

	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_005c/"
	Local _cJson     := ""
	Local _cRet      := ""

	If SA2->(FieldPos("A2_X_TIPFO")) <= 0 .or. Empty(M->A2_X_TIPFO) .or. M->A2_X_TIPFO == "9"
		Return Nil
	EndIf

	_cJson := ' { ' +;
	'"col001c": "'+AllTrim(M->A2_COD+M->A2_LOJA)+'", ' +;
	'"col002n": "", ' +;
	'"col003c": "'+AllTrim(M->A2_NOME)+'", ' +;
	'"col004c": "'+AllTrim(M->A2_END)+'", ' +;
	'"col005c": "'+AllTrim(M->A2_TEL)+'", ' +;
	'"col006c": "'+AllTrim(M->A2_CEP)+'", ' +;
	'"col007c": "'+AllTrim(M->A2_TIPO)+'", ' +;
	'"col008c": "'+AllTrim(M->A2_CGC)+'", ' +;
	'"col009c": "'+AllTrim(M->A2_INSCR)+'", ' +;
	'"col010c": "'+AllTrim(M->A2_INSCRM)+'", ' +;
	'"col011c": "'+If(M->A2_MSBLQL=="1","0","1")+'", ' +;
	'"col012c": "'+AllTrim(M->A2_COD_MUN)+'", ' +;
	'"col013c": "'+AllTrim(M->A2_MUN)+'", ' +;
	'"col014c": "'+AllTrim(M->A2_EST)+'", ' +;
	'"col015c": "'+AllTrim(M->A2_X_TIPFO)+'", ' +;
	'"col016d": "", ' +;
	'"col017d": "'+DtoC(Date())+' '+Time()+' ", ' +;
	'"col018c": "NI", ' +;
	'"col019c": "I" ' +;
	'} '
	_cJson := EncodeUTF8(_cJson, "cp1252")
	_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
	If IsBlind()
		Conout("Integração com PIMS - Inclusão Fornecedor")
		Conout(_cRet)
	Else
		If GetNewPar("NX_AVINTE", "S") == "S"
			MsgInfo(_cRet,"Integração com PIMS - Inclusão Fornecedor")
			Conout("Integração com PIMS - Inclusão Fornecedor")
			Conout(_cRet)
		EndIf
	EndIf

Return Nil

/*/{Protheus.doc}
Ponto de Entrada executado na exclusão do Produto, para alimentar o WS do PIMS
@author Max Ivan (Nexus)
@since 04/08/19
@version P12
@uso Enersugar
@type function
/*/
User Function MT010EXC

	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_003c/"
	Local _cJson     := ""
	Local _cRet      := ""

	If SBM->(FieldPos("BM_X_TPIMS")) <= 0
		Return Nil
	EndIf

	//Somente integra com o PIMS se o campo BM_X_TPIMS estiver preenchido
	SBM->(DbSetOrder(1))
	If SBM->(DbSeek(xFilial("SBM")+M->B1_GRUPO)) .and. !Empty(SBM->BM_X_TPIMS)
		_cJson := ' { ' +;
		'"col001c": "'+AllTrim(M->B1_COD)+'", ' +;
		'"col002n": "", ' +;
		'"col003c": "'+AllTrim(M->B1_GRUPO)+'", ' +;
		'"col004c": "'+AllTrim(Posicione("SBM",1,xFilial("SBM")+M->B1_GRUPO,"BM_DESC"))+'", ' +;
		'"col005c": "'+AllTrim(M->B1_UM)+'", ' +;
		'"col006c": "'+AllTrim(Posicione("SAH",1,xFilial("SAH")+M->B1_UM,"AH_UMRES"))+'", ' +;
		'"col007c": "'+AllTrim(M->B1_DESC)+'", ' +;
		'"col008c": "'+AllTrim(M->B1_GRUPO)+'", ' +;
		'"col009c": "'+If(M->B1_MSBLQL=="1","0","1")+'", ' +;
		'"col010c": "'+AllTrim(M->B1_CONTA)+'", ' +;
		'"col011c": "1", ' +;
		'"col012c": "M", ' +;
		'"col013n": 1, ' +;
		'"col014c": "'+SBM->BM_X_TPIMS+'", ' +;
		'"col015c": "S", ' +;
		'"col016d": "", ' +;
		'"col017d": "'+DtoC(Date())+' '+Time()+' ", ' +;
		'"col018c": "", ' +;
		'"col019c": "D", ' +;
		'"col020d": "" ' +;
		'} '
		_cJson := EncodeUTF8(_cJson, "cp1252")
		_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
		If IsBlind()
			Conout("Integração com PIMS - Exclusão Produto")
			Conout(_cRet)
		Else
			If GetNewPar("NX_AVINTE", "S") == "S"
				MsgInfo(_cRet,"Integração com PIMS - Exclusão Produto")
				Conout("Integração com PIMS - Exclusão Produto")
				Conout(_cRet)
			EndIf
		EndIf
	EndIf

Return Nil

/*/{Protheus.doc}
Ponto de Entrada executado na alteração do Fornecedor, para alimentar o WS do PIMS
@author Max Ivan (Nexus)
@since 04/08/19
@version P12
@uso Enersugar
@type function
/*/
User Function M020ALT

	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_005c/"
	Local _cJson     := ""
	Local _cRet      := ""

	If SA2->(FieldPos("A2_X_TIPFO")) <= 0 .or. Empty(M->A2_X_TIPFO) .or. M->A2_X_TIPFO == "9"
		Return Nil
	EndIf

	_cJson := ' { ' +;
	'"col001c": "'+AllTrim(M->A2_COD+M->A2_LOJA)+'", ' +;
	'"col002n": "", ' +;
	'"col003c": "'+AllTrim(M->A2_NOME)+'", ' +;
	'"col004c": "'+AllTrim(M->A2_END)+'", ' +;
	'"col005c": "'+AllTrim(M->A2_TEL)+'", ' +;
	'"col006c": "'+AllTrim(M->A2_CEP)+'", ' +;
	'"col007c": "'+AllTrim(M->A2_TIPO)+'", ' +;
	'"col008c": "'+AllTrim(M->A2_CGC)+'", ' +;
	'"col009c": "'+AllTrim(M->A2_INSCR)+'", ' +;
	'"col010c": "'+AllTrim(M->A2_INSCRM)+'", ' +;
	'"col011c": "'+If(M->A2_MSBLQL=="1","0","1")+'", ' +;
	'"col012c": "'+AllTrim(M->A2_COD_MUN)+'", ' +;
	'"col013c": "'+AllTrim(M->A2_MUN)+'", ' +;
	'"col014c": "'+AllTrim(M->A2_EST)+'", ' +;
	'"col015c": "'+AllTrim(M->A2_X_TIPFO)+'", ' +;
	'"col016d": "", ' +;
	'"col017d": "'+DtoC(Date())+' '+Time()+' ", ' +;
	'"col018c": "NI", ' +;
	'"col019c": "I" ' +;
	'} '
	_cJson := EncodeUTF8(_cJson, "cp1252")
	_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
	If IsBlind()
		Conout("Integração com PIMS - Alteração Fornecedor")
		Conout(_cRet)
	Else
		If GetNewPar("NX_AVINTE", "S") == "S"
			MsgInfo(_cRet,"Integração com PIMS - Alteração Fornecedor")
			Conout("Integração com PIMS - Alteração Fornecedor")
			Conout(_cRet)
		EndIf
	EndIf

Return Nil

/*/{Protheus.doc}
Ponto de Entrada executado na exclusão do Fornecedor, para alimentar o WS do PIMS
@author Max Ivan (Nexus)
@since 04/08/19
@version P12
@uso Enersugar
@type function
/*/
User Function M020EXC

	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_005c/"
	Local _cJson     := ""
	Local _cRet      := ""

	If SA2->(FieldPos("A2_X_TIPFO")) <= 0 .or. Empty(M->A2_X_TIPFO) .or. M->A2_X_TIPFO == "9"
		Return Nil
	EndIf

	_cJson := ' { ' +;
	'"col001c": "'+AllTrim(M->A2_COD+M->A2_LOJA)+'", ' +;
	'"col002n": "", ' +;
	'"col003c": "'+AllTrim(M->A2_NOME)+'", ' +;
	'"col004c": "'+AllTrim(M->A2_END)+'", ' +;
	'"col005c": "'+AllTrim(M->A2_TEL)+'", ' +;
	'"col006c": "'+AllTrim(M->A2_CEP)+'", ' +;
	'"col007c": "'+AllTrim(M->A2_TIPO)+'", ' +;
	'"col008c": "'+AllTrim(M->A2_CGC)+'", ' +;
	'"col009c": "'+AllTrim(M->A2_INSCR)+'", ' +;
	'"col010c": "'+AllTrim(M->A2_INSCRM)+'", ' +;
	'"col011c": "'+If(M->A2_MSBLQL=="1","0","1")+'", ' +;
	'"col012c": "'+AllTrim(M->A2_COD_MUN)+'", ' +;
	'"col013c": "'+AllTrim(M->A2_MUN)+'", ' +;
	'"col014c": "'+AllTrim(M->A2_EST)+'", ' +;
	'"col015c": "'+AllTrim(M->A2_X_TIPFO)+'", ' +;
	'"col016d": "", ' +;
	'"col017d": "'+DtoC(Date())+' '+Time()+' ", ' +;
	'"col018c": "", ' +;
	'"col019c": "D" ' +;
	'} '
	_cJson := EncodeUTF8(_cJson, "cp1252")
	_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
	If IsBlind()
		Conout("Integração com PIMS - Exclusão Fornecedor")
		Conout(_cRet)
	Else
		If GetNewPar("NX_AVINTE", "S") == "S"
			MsgInfo(_cRet,"Integração com PIMS - Exclusão Fornecedor")
			Conout("Integração com PIMS - Exclusão Fornecedor")
			Conout(_cRet)
		EndIf
	EndIf

Return Nil

/*/{Protheus.doc}
Ponto de Entrada executado na inclusão, Alteração e Exclusão de Centro de Custo, para alimentar o WS do PIMS
@author Max Ivan (Nexus)
@since 04/08/19
@version P12
@uso Enersugar
@type function
/*/
User Function CTA030TOK

	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_006c/"
	Local _cJson     := ""
	Local _cRet      := ""

	_cJson := ' { ' +;
	'"col001c": "'+cEmpAnt+'", ' +;
	'"col002c": "'+cFilAnt+'", ' +;
	'"col003c": "'+AllTrim(M->CTT_CUSTO)+'", ' +;
	'"col004c": "'+AllTrim(M->CTT_DESC01)+'", ' +;
	'"col005c": "", ' +;
	'"col006c": "'+AllTrim(M->CTT_CUSTO)+'", ' +;
	'"col007c": "'+If(M->CTT_BLOQ=="1","0","1")+'", ' +;
	'"col008d": "'+DtoC(Date())+' '+Time()+' ", ' +;
	'"col009d": "", ' +;
	'"col010c": "", ' +;
	'"col011c": "'+If(PARAMIXB==5,"D","I")+'" ' +;
	'} '
	_cJson := EncodeUTF8(_cJson, "cp1252")
	_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
	If IsBlind()
		Conout("Integração com PIMS - Centro de Custo")
		Conout(_cRet)
	Else
		If GetNewPar("NX_AVINTE", "S") == "S"
			MsgInfo(_cRet,"Integração com PIMS - Centro de Custo")
			Conout("Integração com PIMS - Centro de Custo")
			Conout(_cRet)
		EndIf
	EndIf

Return(.F.)

/*/{Protheus.doc}
Ponto de Entrada executado na inclusão, Alteração e Exclusão de Plano de Contas, para alimentar o WS do PIMS
@author Max Ivan (Nexus)
@since 04/08/19
@version P12
@uso Enersugar
@type function
/*/
User Function CTBA020()

	Local aParam     := PARAMIXB
	Local xRet       := .T.
	Local oObj       := ""
	Local cIdPonto   := ""
	Local cIdModel   := ""
	Local lIsGrid    := .F.
	Local nLinha     := 0
	Local nQtdLinhas := 0
	Local cMsg       := ""

	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_007c/"
	Local _cJson     := ""
	Local _cRet      := ""

	If aParam <> NIL
		oObj := aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]
		lIsGrid := (Len(aParam) > 3)
		/*For _nI := 2 to Len(aParam)
		Alert(Str(_nI)+aParam[_nI])
		Next*/
		If cIdPonto == "MODELCOMMITNTTS"
			_cJson := ' { ' +;
			'"col001c": "'+cEmpAnt+'", ' +;
			'"col002c": "'+cFilAnt+'", ' +;
			'"col003c": "'+AllTrim(CT1->CT1_CONTA)+'", ' +;
			'"col004c": "'+AllTrim(CT1->CT1_DESC01)+'", ' +;
			'"col005c": "'+If(CT1->CT1_BLOQ=="1","0","1")+'", ' +;
			'"col006c": "1", ' +;
			'"col007c": "1", ' +;
			'"col008d": "'+DtoC(Date())+' '+Time()+' ", ' +;
			'"col009d": "", ' +;
			'"col010c": "NI", ' +;
			'"col011c": "'+If(INCLUI .or. ALTERA,"I","D")+'" ' +;
			'} '
			_cJson := EncodeUTF8(_cJson, "cp1252")
			_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
			If IsBlind()
				Conout("Integração com PIMS - Conta Contabil")
				Conout(_cRet)
			Else
				If GetNewPar("NX_AVINTE", "S") == "S"
					MsgInfo(_cRet,"Integração com PIMS - Conta Contabil")
					Conout("Integração com PIMS - Conta Contabil")
					Conout(_cRet)
				EndIf
			EndIf
		EndIf
	EndIf

Return(xRet)

User Function M185GRV

	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_042m/"
	Local _aArAtu    := GetArea()
	Local _aArSCP    := SCP->(GetArea())
	Local _cCol008   := "AT"
	Local _cxIDPIMS  := ""
	Local _cOrPIMS   := ""

	SCP->(DbSetOrder(1))
	If SCP->(DbSeek(xFilial("SCP")+SD3->D3_NUMSA+SD3->D3_ITEMSA))
		_cCol008  := If(SCP->CP_QUJE == SCP->CP_QUANT,"AT","AP") //If(SD3->D3_QUANT+SCP->CP_QUJE >= SCP->CP_QUANT,"AT","AP")
		_cxIDPIMS := SCP->CP_XIDPIMS
		_cOrPIMS  := SCP->CP_XORPIMS
	EndIf

	If Empty(_cxIDPIMS) .or. _cOrPIMS # "041M"
		Return
	EndIf

	MsgInfo("D3_NUMSA: "  + SD3->D3_NUMSA  + enter +;
	"D3_ITEMSA: " + SD3->D3_ITEMSA + enter +;
	"D3_OSTEC: "  + SD3->D3_OSTEC  + enter +;
	"Qtde: " + AllTrim(Str(SD3->D3_QUANT)) + enter +;
	"col008c: " + _cCol008)

	_cJson := ' { ' +;
	'"col001n": 1, ' +;
	'"col002n": '+AllTrim(_cxIDPIMS)+', ' +;
	'"col003d": "'+DtoC(Date())+' '+Time()+' ", ' +;
	'"col004n": '+AllTrim(Str(SD3->D3_QUANT))+', ' +;
	'"col005c": "'+SD3->D3_UM+'", ' +;
	'"col006n": '+AllTrim(Str(SD3->D3_CUSTO1/SD3->D3_QUANT))+', ' +;
	'"col007n": '+AllTrim(Str(SD3->D3_CUSTO1/SD3->D3_QUANT))+', ' +;
	'"col008c": "'+_cCol008+'", ' +;
	'"col009d": "'+DtoC(Date())+' '+Time()+' ", ' +;
	'"col010d": "'+DtoC(Date())+' '+Time()+' ", ' +;
	'"col011c": "'+SD3->D3_NUMSA+SD3->D3_ITEMSA+'", ' +;
	'"col012c": "NI", ' +;
	'"col013c": "I" ' +;
	'} '
	_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
	MsgInfo(_cRet)

	RestArea(_aArSCP)
	RestArea(_aArAtu)

Return

User Function M185EST

	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_042m/"
	Local _aArAtu    := GetArea()
	Local _aArSCP    := SCP->(GetArea())
	Local _cCol008   := "AT"
	Local _cOrPIMS   := ""

	If Empty(SD3->D3_OSTEC)
		Return
	EndIf

	SCP->(DbSetOrder(1))
	If SCP->(DbSeek(xFilial("SCP")+SD3->D3_NUMSA+SD3->D3_ITEMSA))
		_cCol008 := If(SD3->D3_QUANT+SCP->CP_QUJE >= SCP->CP_QUANT,"AT","AP")
		_cOrPIMS := SCP->CP_XORPIMS
	EndIf

	If _cOrPIMS # "041M"
		Return
	EndIf

	MsgInfo("M185EST" + enter +;
	"D3_NUMSA: "  + SD3->D3_NUMSA  + enter +;
	"D3_ITEMSA: " + SD3->D3_ITEMSA + enter +;
	"D3_OSTEC: "  + SD3->D3_OSTEC  + enter +;
	"Qtde: " + AllTrim(Str(SD3->D3_QUANT*-1)) + enter +;
	"col008c: " + _cCol008)

	_cJson := ' { ' +;
	'"col001n": 1, ' +;
	'"col002n": '+AllTrim(SD3->D3_OSTEC)+', ' +;
	'"col003d": "'+DtoC(Date())+' '+Time()+' ", ' +;
	'"col004n": '+AllTrim(Str(SD3->D3_QUANT*-1))+', ' +;
	'"col005c": "'+SD3->D3_UM+'", ' +;
	'"col006n": '+AllTrim(Str(SD3->D3_CUSTO1/SD3->D3_QUANT))+', ' +;
	'"col007n": '+AllTrim(Str(SD3->D3_CUSTO1/SD3->D3_QUANT))+', ' +;
	'"col008c": "'+_cCol008+'", ' +;
	'"col009d": "'+DtoC(Date())+' '+Time()+' ", ' +;
	'"col010d": "'+DtoC(Date())+' '+Time()+' ", ' +;
	'"col011c": "'+SD3->D3_NUMSA+SD3->D3_ITEMSA+'", ' +;
	'"col012c": "NI", ' +;
	'"col013c": "I" ' +;
	'} '
	_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
	MsgInfo(_cRet)

	RestArea(_aArSCP)
	RestArea(_aArAtu)

Return

//Tabela intermediária de Produtos - Carga de Produtos (SB1)
User Function CARGA003C(_aParam)

	If IsBlind()
		RpcSetType(3)
		RpcSetEnv(_cEmpJob, _cFilJob,,,'EST')
	EndIf

	If !IsBlind()
		GProcSB1()
	Else
		RProcSB1()
		RpcClearEnv()
	EndIf

Return

Static Function GProcSB1()

	// Inicializa a regua de processamento
	Processa({|| RProcSB1() },"Processando Produtos ...")

Return Nil

Static Function RProcSB1

	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_003c/"
	Local _cResouNNR := "/totvs-1.0/int_pims_008c/"
	Local _cResouSB2 := "/totvs-1.0/int_pims_004c/"
	Local _cJson     := ""
	Local _cRet      := ""
	Local _aArAtu    := GetArea()
	Local _aArSB1    := SB1->(GetArea())
	Local _nTotRegs  := 0

	If SBM->(FieldPos("BM_X_TPIMS")) <= 0
		Return
	EndIf

	SB1->(DbSetOrder(1))
	SB1->(DbGoTop())
	If !IsBlind()
		ProcRegua(SB1->(RecCount())) //ProcRegua(QUERY->(RECCOUNT()))
	EndIf

	While SB1->(!Eof())
		//Somente integra com o PIMS se o campo BM_X_TPIMS estiver preenchido
		SBM->(DbSetOrder(1))
		If SBM->(DbSeek(xFilial("SBM")+SB1->B1_GRUPO)) .and. !Empty(SBM->BM_X_TPIMS)
			//DEPOSITO
			NNR->(DbSetOrder(1))
			NNR->(DbSeek(xFilial("NNR")+SB1->B1_LOCPAD))
			_cJson := ' { ' +;
			'"col001c": "'+cEmpAnt+'", ' +;
			'"col002c": "'+cFilAnt+'", ' +;
			'"col003c": "'+AllTrim(NNR->NNR_CODIGO)+'", ' +;
			'"col004c": "'+AllTrim(NNR->NNR_DESCRI)+'", ' +;
			'"col005c": "1", ' +;
			'"col006c": "F", ' +;
			'"col007d": "'+DtoC(Date())+' '+Time()+' ", ' +;
			'"col010c": "I"' +;
			'} '
			_cJson := EncodeUTF8(_cJson, "cp1252")
			_cRet := U_WCRestJson(_cEndPoint,_cResouNNR,_cJson)
			If IsBlind()
				Conout("Integração com PIMS - Inclusão Depósito")
				Conout(_cRet)
			Else
			EndIf

			//SALDOS NOS DEPOSITOS
			SB2->(DbSetOrder(1))
			If SB2->(DbSeek(xFilial("SB2")+SB1->B1_COD))
				While SB2->(!Eof()) .and. xFilial("SB2")+SB1->B1_COD == SB2->B2_FILIAL+SB2->B2_COD
					_cJson := ' { ' +;
					'"col001c": "'+cEmpAnt+'", ' +;
					'"col002c": "'+cFilAnt+'", ' +;
					'"col003c": "'+AllTrim(SB1->B1_COD)+'", ' +;
					'"col004c": "'+AllTrim(SB2->B2_LOCAL)+'", ' +;
					'"col005n": '+AllTrim(Str(SB2->B2_QATU))+', ' +;
					'"col006n": '+AllTrim(Str(SB2->B2_CM1))+', ' +;
					'"col007n": '+AllTrim(Str(SB1->B1_UPRC))+', ' +;
					'"col008c": "1", ' +;
					'"col009c": "'+AllTrim(SB1->B1_CONTA)+'", ' +;
					'"col010d": "'+If(!Empty(SB1->B1_UCOM),DtoC(SB1->B1_UCOM)+' '+Time(),"")+'", ' +;
					'"col011d": "'+DtoC(Date())+' '+Time()+' ", ' +;
					'"col012d": "", ' +;
					'"col013c": "NI", ' +;
					'"col014c": "I"' +;
					'} '
					_cJson := EncodeUTF8(_cJson, "cp1252")
					_cRet := U_WCRestJson(_cEndPoint,_cResouSB2,_cJson)
					If IsBlind()
						Conout("Integração com PIMS - Inclusão Saldo")
						Conout(_cRet)
					Else
					EndIf

					SB2->(DbSkip())
				EndDo
			EndIf

			//PRODUTO
			_cJson := ' { ' +;
			'"col001c": "'+AllTrim(SB1->B1_COD)+'", ' +;
			'"col002n": "", ' +;
			'"col003c": "'+AllTrim(SB1->B1_GRUPO)+'", ' +;
			'"col004c": "'+AllTrim(Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC"))+'", ' +;
			'"col005c": "'+AllTrim(SB1->B1_UM)+'", ' +;
			'"col006c": "'+AllTrim(Posicione("SAH",1,xFilial("SAH")+SB1->B1_UM,"AH_UMRES"))+'", ' +;
			'"col007c": "'+AllTrim(SB1->B1_DESC)+'", ' +;
			'"col008c": "'+AllTrim(SB1->B1_GRUPO)+'", ' +;
			'"col009c": "'+If(SB1->B1_MSBLQL=="1","0","1")+'", ' +;
			'"col010c": "'+AllTrim(SB1->B1_CONTA)+'", ' +;
			'"col011c": "1", ' +;
			'"col012c": "M", ' +;
			'"col013n": 1, ' +;
			'"col014c": "'+SBM->BM_X_TPIMS+'", ' +;
			'"col015c": "S", ' +;
			'"col016d": "", ' +;
			'"col017d": "'+DtoC(Date())+' '+Time()+' ", ' +;
			'"col018c": "", ' +;
			'"col019c": "I", ' +;
			'"col020d": "" ' +;
			'} '
			_cJson := EncodeUTF8(_cJson, "cp1252")
			_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
			If IsBlind()
				Conout("Integração com PIMS - Inclusão Produto")
				Conout(_cRet)
			Else
			EndIf
			_nTotRegs++
		EndIf
		If !IsBlind()
			IncProc("Processando Produtos: "+SB1->B1_COD)
		EndIf
		SB1->(DbSkip())
	EndDo

	MsgInfo("Carga Finalizada. Total de Registros: "+TransForm(_nTotRegs,"@E 999,999"))

	RestArea(_aArSB1)
	RestArea(_aArAtu)

Return

//Tabela intermediária de Fornecedores - Carga de Fornecedores (SA2)
User Function CARGA005C(_aParam)

	If IsBlind()
		RpcSetType(3)
		RpcSetEnv(_cEmpJob, _cFilJob,,,'EST')
	EndIf

	If !IsBlind()
		GProcSA2()
	Else
		RProcSA2()
		RpcClearEnv()
	EndIf

Return

Static Function GProcSA2()

	// Inicializa a regua de processamento
	Processa({|| RProcSA2() },"Processando Produtos ...")

Return Nil

Static Function RProcSA2

	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_005c/"
	Local _cJson     := ""
	Local _cRet      := ""
	Local _nTotRegs  := 0

	SA2->(DbSetOrder(1))
	SA2->(DbGoTop())
	If !IsBlind()
		ProcRegua(SA2->(RecCount())) //ProcRegua(QUERY->(RECCOUNT()))
	EndIf

	While SA2->(!Eof())
		If Empty(SA2->A2_X_TIPFO) .or. SA2->A2_X_TIPFO == "9"
			SA2->(DbSkip())
			Loop
		EndIf

		_cJson := ' { ' +;
		'"col001c": "'+AllTrim(SA2->A2_COD+SA2->A2_LOJA)+'", ' +;
		'"col002n": "", ' +;
		'"col003c": "'+AllTrim(SA2->A2_NOME)+'", ' +;
		'"col004c": "'+AllTrim(SA2->A2_END)+'", ' +;
		'"col005c": "'+AllTrim(SA2->A2_TEL)+'", ' +;
		'"col006c": "'+AllTrim(SA2->A2_CEP)+'", ' +;
		'"col007c": "'+AllTrim(SA2->A2_TIPO)+'", ' +;
		'"col008c": "'+AllTrim(SA2->A2_CGC)+'", ' +;
		'"col009c": "'+AllTrim(SA2->A2_INSCR)+'", ' +;
		'"col010c": "'+AllTrim(SA2->A2_INSCRM)+'", ' +;
		'"col011c": "'+If(SA2->A2_MSBLQL=="1","0","1")+'", ' +;
		'"col012c": "'+AllTrim(SA2->A2_COD_MUN)+'", ' +;
		'"col013c": "'+AllTrim(SA2->A2_MUN)+'", ' +;
		'"col014c": "'+AllTrim(SA2->A2_EST)+'", ' +;
		'"col015c": "'+AllTrim(SA2->A2_X_TIPFO)+'", ' +;
		'"col016d": "", ' +;
		'"col017d": "'+DtoC(Date())+' '+Time()+' ", ' +;
		'"col018c": "NI", ' +;
		'"col019c": "I" ' +;
		'} '
		_cJson := EncodeUTF8(_cJson, "cp1252")
		_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
		If IsBlind()
			Conout("Integração com PIMS - Inclusão Fornecedor")
			Conout(_cRet)
		Else
		EndIf
		_nTotRegs++
		If !IsBlind()
			IncProc("Processando Fornecedores: "+SA2->A2_COD+SA2->A2_LOJA)
		EndIf
		SA2->(DbSkip())
	EndDo

	MsgInfo("Carga Finalizada. Total de Registros: "+TransForm(_nTotRegs,"@E 999,999"))

Return

/*/{Protheus.doc} M410AGRV
Ponto de entrada na gravacao do pedido de venda
para integração com a Pesagem PIMS (INT_PIMS_091M)
@author Max Ivan (Nexus)
@since 04/05/20
@version P12
@uso Especifico Enersugar
@type function
/*/
User Function M410AGRV()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Local _aArea  := GetArea()
	Local _aArSC5 := SC5->(GetArea())
	Local _aArSC6 := SC6->( GetArea() )
	//-----------------------------------------------------------------------
	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_091m/"
	Local _cJson     := ""
	Local _cRet      := ""
	Local _cNumPv    := M->C5_NUM     //If(PARAMIXB[1] == 1,M->C5_NUM,SC5->C5_NUM)
	Local _cPesa     := M->C5_X_PESA  //If(PARAMIXB[1] == 1,M->C5_X_PESA,SC5->C5_X_PESA)
	Local _cCodCli   := M->C5_CLIENTE //If(PARAMIXB[1] == 1,M->C5_CLIENTE,SC5->C5_CLIENTE)
	Local _cLojCli   := M->C5_LOJACLI //If(PARAMIXB[1] == 1,M->C5_LOJACLI,SC5->C5_LOJACLI)
	Local _cTransp   := M->C5_TRANSP  //If(PARAMIXB[1] == 1,M->C5_TRANSP,SC5->C5_TRANSP)
	Local _cVeicu1   := M->C5_VEICULO //If(PARAMIXB[1] == 1,M->C5_VEICULO,SC5->C5_VEICULO)
	Local _cVeicu2   := M->C5_X_VEIC2
	Local _cVeicu3   := M->C5_X_VEIC3
	Local _dEmissa   := M->C5_EMISSAO //If(PARAMIXB[1] == 1,M->C5_EMISSAO,SC5->C5_EMISSAO)
	Local _cNomeCli  := ""
	Local _cCGCCli   := ""

	Local _nPosIte := AScan( aHeader, {|x| AllTrim( x[2] ) == 'C6_ITEM'} )
	Local _nPosPrd := AScan( aHeader, {|x| AllTrim( x[2] ) == 'C6_PRODUTO'} )
	Local _nPosQtd := AScan( aHeader, {|x| AllTrim( x[2] ) == 'C6_QTDVEN'} )
	Local _nPosPrc := AScan( aHeader, {|x| AllTrim( x[2] ) == 'C6_PRCVEN'} )
	Local _nPosLst := AScan( aHeader, {|x| AllTrim( x[2] ) == 'C6_PRUNIT'} )
	Local _nPosTES := AScan( aHeader, {|x| AllTrim( x[2] ) == 'C6_TES'} )
	Local _nPosLoc := AScan( aHeader, {|x| AllTrim( x[2] ) == 'C6_LOCAL'} )
	Local _nPosUm  := AScan( aHeader, {|x| AllTrim( x[2] ) == 'C6_UM'} )
	Local _nPosUm2 := AScan( aHeader, {|x| AllTrim( x[2] ) == 'C6_SEGUM'} )
	Local nCount   := 1
	Local _nQtde   := 0
	Local _nUM     := ""

	//Alert("M410AGRV "+Str(PARAMIXB[1])+" "+_cNumPv)

	//If (PARAMIXB[1] == 1 .or. PARAMIXB[1] == 2) .and. SC5->(FieldPos("C5_X_PESA")) > 0 .and. _cPesa == "S"
	If SC5->(FieldPos("C5_X_PESA")) > 0 .and. _cPesa == "S"
		For nCount := 1 To Len(aCols)
		//SC6->(DbSetOrder(1))
		//If SC6->(DbSeek(xFilial("SC6")+_cNumPv))
			//While SC6->(!Eof()) .and. xFilial("SC6")+_cNumPv == SC6->C6_FILIAL+SC6->C6_NUM
				//Alert(SC6->C6_ITEM)
				SB1->(DbSetOrder(1))
				SB1->(DbSeek(xFilial("SB1")+aCols[nCount,_nPosPrd]))
				NNR->(DbSetOrder(1))
				NNR->(DbSeek(xFilial("NNR")+aCols[nCount,_nPosLoc]))
				If M->C5_TIPO $ "DB"
				   SA2->(DbSetOrder(1))
				   If SA2->(DbSeek(xFilial("SA2")+_cCodCli+_cLojCli))
				      _cNomeCli  := SA2->A2_NOME
					  _cCGCCli   := SA2->A2_CGC
				   EndIf
				Else
				   SA1->(DbSetOrder(1))
				   If SA1->(DbSeek(xFilial("SA1")+_cCodCli+_cLojCli))
				      _cNomeCli  := SA1->A1_NOME
					  _cCGCCli   := SA1->A1_CGC
				   EndIf
				EndIf
				SA4->(DbSetOrder(1))
				SA4->(DbSeek(xFilial("SA4")+_cTransp))
				DA3->(DbSetOrder(1))
				DA3->(DbSeek(xFilial("DA3")+_cVeicu1))
				DA4->(DbSetOrder(1))
				DA4->(DbSeek(xFilial("DA4")+DA3->DA3_MOTORI))
				SF4->(DbSetOrder(1))
				SF4->(DbSeek(xFilial("SF4")+aCols[nCount,_nPosTES]))
				If SB1->B1_X_PESA = "S" .and. SF4->F4_ESTOQUE == "S"
					If AllTrim(aCols[nCount,_nPosUm2]) $ "KG|L" .and. SB1->B1_CONV > 0 .and. !Empty(SB1->B1_TIPCONV)
						_nQtde := If(SB1->B1_TIPCONV=="D",aCols[nCount,_nPosQtd]*SB1->B1_CONV,aCols[nCount,_nPosQtd]/SB1->B1_CONV)
						_nUM   := aCols[nCount,_nPosUm2]
					Else
						_nQtde := aCols[nCount,_nPosQtd]
						_nUM   := aCols[nCount,_nPosUm]
					EndIf
					//Alert("2 "+SC6->C6_ITEM)
					_cJson := ' { ' +;
					'"col001n": 1, ' +;
					'"col002c": "'+cEmpAnt+'", ' +;
					'"col003c": "'+cFilAnt+'", ' +;
					'"col004c": "'+_cNumPv+aCols[nCount,_nPosIte]+'", ' +;
					'"col005c": "", ' +;
					'"col006c": "'+AllTrim(aCols[nCount,_nPosPrd])+'", ' +;
					'"col007c": "'+AllTrim(SB1->B1_DESC)+'", ' +;
					'"col008c": "'+AllTrim(_nUM)+'", ' +;
					'"col009c": "'+AllTrim(aCols[nCount,_nPosLoc])+'", ' +;
					'"col010c": "'+AllTrim(NNR->NNR_DESCRI)+'", ' +;
					'"col011n": '+AllTrim(Str(_nQtde))+', ' +;
					'"col012c": "'+AllTrim(_cTransp)+'", ' +;
					'"col013c": "'+AllTrim(SA4->A4_NOME)+'", ' +;
					'"col014c": "'+AllTrim(SA4->A4_CGC)+'", ' +;
					'"col015c": "'+AllTrim(DA3->DA3_PLACA)+'", ' +;
					'"col016c": "'+AllTrim(Posicione("DA3",1,xFilial("DA3")+_cVeicu2,"DA3_PLACA"))+'", ' +;
					'"col017c": "'+AllTrim(Posicione("DA3",1,xFilial("DA3")+_cVeicu3,"DA3_PLACA"))+'", ' +;
					'"col018c": "'+AllTrim(DA3->DA3_ESTPLA)+'", ' +;
					'"col019c": "'+AllTrim(Posicione("DA3",1,xFilial("DA3")+_cVeicu2,"DA3_ESTPLA"))+'", ' +;
					'"col020c": "'+AllTrim(Posicione("DA3",1,xFilial("DA3")+_cVeicu3,"DA3_ESTPLA"))+'", ' +;
					'"col021c": "'+AllTrim(DA4->DA4_NOME)+'", ' +;
					'"col022c": "'+AllTrim(DA3->DA3_MOTORI)+'", ' +;
					'"col023c": "'+AllTrim(_cCodCli+_cLojCli)+'", ' +;
					'"col024c": "'+AllTrim(_cNomeCli)+'", ' +;
					'"col025c": "'+AllTrim(_cCGCCli)+'", ' +;
					'"col026c": "", ' +;
					'"col027c": "", ' +;
					'"col028c": "'+If(PARAMIXB[1] == 3,"04","00")+'", ' +;
					'"col029c": "", ' +;
					'"col030n": 0, ' +;
					'"col031d": "'+DtoC(_dEmissa)+'", ' +;
					'"col032n": 0, ' +;
					'"col033n": 0, ' +;
					'"col034n": 0, ' +;
					'"col035n": 0, ' +;
					'"col036c": "", ' +;
					'"col037d": "'+DtoC(Date())+' '+Time()+'", ' +;
					'"col038n": 0, ' +;
					'"col039n": 0, ' +;
					'"col040c": "", ' +;
					'"col041n": 0, ' +;
					'"col042n": 0, ' +;
					'"col043n": 0, ' +;
					'"col044n": 0, ' +;
					'"col045n": 0, ' +;
					'"col046d": "", ' +;
					'"col047c": "", ' +;
					'"col048d": "", ' +;
					'"col049c": "", ' +;
					'"col050n": 0, ' +;
					'"col051c": "", ' +;
					'"col052c": "", ' +;
					'"col053c": "", ' +;
					'"col054d": "'+DtoC(Date())+' '+Time()+'", ' +;
					'"col055d": "", ' +;
					'"col056d": "", ' +;
					'"col057c": "" ' +;
					'} '
					_cJson := EncodeUTF8(_cJson, "cp1252")
					MemoWrite("c:/spool/091M_00.txt", _cJson )
					_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
					If IsBlind()
						Conout("Integração com PIMS - Pesagem - Status: 00")
						Conout(_cRet)
					Else
						MsgInfo(_cRet,"Integração com PIMS - Pesagem - Status: 00")
					EndIf
				EndIf
				SC6->(DbSkip())
			//EndDo
		//EndIf
		Next
	EndIf

	//-----------------------------------------------------------------------
	RestArea(_aArSC6)
	RestArea(_aArSC5)
	RestArea(_aArea)

Return

User Function M410PVNF()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³OBSERVAÇÃO: TODOS AJUSTES FEITOS NESTE RDMAKE, DEVEM OBRIGATORIAMENTE SER FEITOS NO RDMAKE M460MARK TB³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Local lReturn := .T.
	Local _aArAtu := GetArea()
	Local _aArSC5 := SC5->(GetArea())
	Local _aArSC6 := SC6->(GetArea())
	Local _aArSB1 := SB1->(GetArea())
	Local _aArSF4 := SF4->(GetArea())

	//Alert("M410PVNF")
	If SC5->(FieldPos("C5_X_PESA")) > 0 .and. SC5->C5_X_PESA == "S"
		SC6->(DbSetOrder(1))
		If SC6->(DbSeek(xFilial("SC6")+SC5->C5_NUM))
			While SC6->(!Eof()) .and. xFilial("SC6")+SC5->C5_NUM == SC6->C6_FILIAL+SC6->C6_NUM
				SB1->(DbSetOrder(1))
				SB1->(DbSeek(xFilial("SB1")+SC6->C6_PRODUTO))
				SF4->(DbSetOrder(1))
				SF4->(DbSeek(xFilial("SF4")+SC6->C6_TES))
				If SB1->B1_X_PESA == "S" .and. SF4->F4_ESTOQUE == "S" .and. SC6->C6_X_ORIQT == 0
					Alert("Não é possível Faturar, pois não houve retorno da pesagem!!!")
					lReturn := .F.
				EndIf
				SC6->(DbSkip())
			EndDo
		EndIf
	EndIf

	RestArea(_aArSC5)
	RestArea(_aArSC6)
	RestArea(_aArSB1)
	RestArea(_aArSF4)
	RestArea(_aArAtu)

	Return(lReturn)

//User Function M460FIM //RETIRADO CONFORME TROCA DE MENSAGENS COM O RENAN EM 25/05/2021
User Function M460PIMS

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Local _aArea  := GetArea()
	Local _aArSC5 := SC5->(GetArea())
	Local _aArSC6 := SC6->( GetArea() )
	//-----------------------------------------------------------------------
	Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
	Local _cResource := "/totvs-1.0/int_pims_091m/"
	Local _cJson     := ""
	Local _cRet      := ""
	Local _cNomeCli  := ""
	Local _cCGCCli   := ""
	Local _nQtde     := 0
	Local _nUM       := ""

	//Alert("M460FIM")

	SD2->(DbSetOrder(3))
	If SD2->(DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE))
		While SD2->(!Eof()) .and. xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE == SD2->D2_FILIAL+SD2->D2_DOC+SD2->D2_SERIE
			SC6->(DbSetOrder(1))
			If SC6->(DbSeek(xFilial("SC6")+SD2->D2_PEDIDO+SD2->D2_ITEMPV))
				If SC6->(FieldPos("C6_X_ORIQT")) > 0 .and. SC6->C6_X_ORIQT > 0 
					SB1->(DbSetOrder(1))
					SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD))
					If AllTrim(SC6->C6_SEGUM) $ "KG|L" .and. SB1->B1_CONV > 0 .and. !Empty(SB1->B1_TIPCONV)
						_nQtde := If(SB1->B1_TIPCONV=="D",SC6->C6_QTDVEN*SB1->B1_CONV,SC6->C6_QTDVEN/SB1->B1_CONV)
						_nUM   := SC6->C6_SEGUM
					Else
						_nQtde := SC6->C6_QTDVEN
						_nUM   := SC6->C6_UM
					EndIf
					NNR->(DbSetOrder(1))
					NNR->(DbSeek(xFilial("NNR")+SD2->D2_LOCAL))
					If SF2->F2_TIPO $ "DB"
						SA2->(DbSetOrder(1))
						If SA2->(DbSeek(xFilial("SA2")+SF2->F2_CLIENTE+SF2->F2_LOJA))
							_cNomeCli  := SA2->A2_NOME
							_cCGCCli   := SA2->A2_CGC
						EndIf
					Else
						SA1->(DbSetOrder(1))
						If SA1->(DbSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA))
							_cNomeCli  := SA1->A1_NOME
							_cCGCCli   := SA1->A1_CGC
						EndIf
					EndIf
					SA4->(DbSetOrder(1))
					SA4->(DbSeek(xFilial("SA4")+SF2->F2_TRANSP))
					DA3->(DbSetOrder(1))
					DA3->(DbSeek(xFilial("DA3")+SF2->F2_VEICUL1))
					DA4->(DbSetOrder(1))
					DA4->(DbSeek(xFilial("DA4")+DA3->DA3_MOTORI))
					_cJson := ' { ' +;
					'"col001n": 1, ' +;
					'"col002c": "'+cEmpAnt+'", ' +;
					'"col003c": "'+cFilAnt+'", ' +;
					'"col004c": "'+SC6->C6_NUM+SC6->C6_ITEM+'", ' +;
					'"col005c": "'+AllTrim(SF2->F2_SERIE+SF2->F2_DOC)+'", ' +;
					'"col006c": "'+AllTrim(SC6->C6_PRODUTO)+'", ' +;
					'"col007c": "'+AllTrim(SB1->B1_DESC)+'", ' +;
					'"col008c": "'+AllTrim(_nUM)+'", ' +;
					'"col009c": "'+AllTrim(SC6->C6_LOCAL)+'", ' +;
					'"col010c": "'+AllTrim(NNR->NNR_DESCRI)+'", ' +;
					'"col011n": '+AllTrim(Str(_nQtde))+', ' +;
					'"col012c": "'+AllTrim(SF2->F2_TRANSP)+'", ' +;
					'"col013c": "'+AllTrim(SA4->A4_NOME)+'", ' +;
					'"col014c": "'+AllTrim(SA4->A4_CGC)+'", ' +;
					'"col015c": "'+AllTrim(DA3->DA3_PLACA)+'", ' +;
					'"col016c": "'+AllTrim(Posicione("DA3",1,xFilial("DA3")+SC5->C5_X_VEIC2,"DA3_PLACA"))+'", ' +;
					'"col017c": "'+AllTrim(Posicione("DA3",1,xFilial("DA3")+SC5->C5_X_VEIC3,"DA3_PLACA"))+'", ' +;
					'"col018c": "'+AllTrim(DA3->DA3_ESTPLA)+'", ' +;
					'"col019c": "'+AllTrim(Posicione("DA3",1,xFilial("DA3")+SC5->C5_X_VEIC2,"DA3_ESTPLA"))+'", ' +;
					'"col020c": "'+AllTrim(Posicione("DA3",1,xFilial("DA3")+SC5->C5_X_VEIC3,"DA3_ESTPLA"))+'", ' +;
					'"col021c": "'+AllTrim(DA4->DA4_NOME)+'", ' +;
					'"col022c": "'+AllTrim(DA3->DA3_MOTORI)+'", ' +;
					'"col023c": "'+AllTrim(SF2->F2_CLIENTE+SF2->F2_LOJA)+'", ' +;
					'"col024c": "'+AllTrim(SA1->A1_NOME)+'", ' +;
					'"col025c": "'+AllTrim(SA1->A1_CGC)+'", ' +;
					'"col026c": "", ' +;
					'"col027c": "", ' +;
					'"col028c": "03", ' +;
					'"col029c": "", ' +;
					'"col030n": 0, ' +;
					'"col031d": "'+DtoC(SF2->F2_EMISSAO)+'", ' +;
					'"col032n": 0, ' +;
					'"col033n": 0, ' +;
					'"col034n": 0, ' +;
					'"col035n": 0, ' +;
					'"col036c": "", ' +;
					'"col037d": "'+DtoC(Date())+' '+Time()+'", ' +;
					'"col038n": 0, ' +;
					'"col039n": 0, ' +;
					'"col040c": "", ' +;
					'"col041n": 0, ' +;
					'"col042n": 0, ' +;
					'"col043n": 0, ' +;
					'"col044n": 0, ' +;
					'"col045n": 0, ' +;
					'"col046d": "", ' +;
					'"col047c": "", ' +;
					'"col048d": "", ' +;
					'"col049c": "", ' +;
					'"col050n": 0, ' +;
					'"col051c": "", ' +;
					'"col052c": "", ' +;
					'"col053c": "", ' +;
					'"col054d": "'+DtoC(Date())+' '+Time()+'", ' +;
					'"col055d": "", ' +;
					'"col056d": "'+DtoC(Date())+' '+Time()+'", ' +;
					'"col057c": "" ' +;
					'} '
					_cJson := EncodeUTF8(_cJson, "cp1252")
					MemoWrite("c:/spool/091M_03.txt", _cJson )
					_cRet := U_WCRestJson(_cEndPoint,_cResource,_cJson)
					If IsBlind()
						Conout("Integração com PIMS - Pesagem - Status: 03")
						Conout(_cRet)
					Else
						MsgInfo(_cRet,"Integração com PIMS - Pesagem - Status: 03")
					EndIf
				EndIf
			EndIf
			SD2->(DbSkip())
		EndDo
	EndIf
	If RecLock("SF2",.F.)
		SF2->F2_VEICUL2 := SC5->C5_X_VEIC2
		SF2->F2_VEICUL3 := SC5->C5_X_VEIC3
		SF2->(MsUnLock())
	EndIf
	//-----------------------------------------------------------------------
	RestArea(_aArSC6)
	RestArea(_aArSC5)
	RestArea(_aArea)

Return

//Tabela intermediária de Itens - Saldos em Estoque (SB2)
User Function PIMS004C(_aParam)

Private cPerg := "PIMS004C"
Private _lBat     := Iif(IsBlind(),.T.,.F.)
Private _cEmpJob  := iif(_aParam == NIL, "01", _aParam[1])
Private _cFilJob  := iif(_aParam == NIL, "0101", _aParam[2])

If _lBat
   RpcSetType(3)
   RpcSetEnv(_cEmpJob, _cFilJob,,,'EST')
EndIf

If !_lBat
   GProcArq()
Else
   RProcArq()
   RpcClearEnv()
EndIf

Return

Static Function GProcArq()

// Inicializa a regua de processamento
Processa({|| RProcArq() },"Processando Estoque ...")

Return Nil

Static Function RProcArq

Local _cEndPoint := GetNewPar("NX_WSPIMS", "http://187.94.62.118:8380")
Local _cResouSB2 := "/totvs-1.0/int_pims_004c/"
Local _cJson     := ""
Local _cRet      := ""

If SBM->(FieldPos("BM_X_TPIMS")) <= 0
   Return
EndIf

SB1->(DbSetOrder(1))
SB1->(DbGoTop())
If !IsBlind()
	ProcRegua(SB1->(RecCount())) //ProcRegua(QUERY->(RECCOUNT()))
EndIf

While SB1->(!Eof())
   //Somente integra com o PIMS se o campo BM_X_TPIMS estiver preenchido
   SBM->(DbSetOrder(1))
   If SBM->(DbSeek(xFilial("SBM")+SB1->B1_GRUPO)) .and. !Empty(SBM->BM_X_TPIMS)
      //SALDOS NOS DEPOSITOS
      SB2->(DbSetOrder(1))
      If SB2->(DbSeek(xFilial("SB2")+SB1->B1_COD))
         While SB2->(!Eof()) .and. xFilial("SB2")+SB1->B1_COD == SB2->B2_FILIAL+SB2->B2_COD
            _cJson := ' { ' +;
                      '"col001c": "'+cEmpAnt+'", ' +;
                      '"col002c": "'+cFilAnt+'", ' +;
                      '"col003c": "'+AllTrim(SB1->B1_COD)+'", ' +;
                      '"col004c": "'+AllTrim(SB2->B2_LOCAL)+'", ' +;
                      '"col005n": '+AllTrim(Str(SB2->B2_QATU))+', ' +;
                      '"col006n": '+AllTrim(Str(SB2->B2_CM1))+', ' +;
                      '"col007n": '+AllTrim(Str(SB1->B1_UPRC))+', ' +;
                      '"col008c": "1", ' +;
                      '"col009c": "'+AllTrim(SB1->B1_CONTA)+'", ' +;
                      '"col010d": "'+If(!Empty(SB1->B1_UCOM),DtoC(SB1->B1_UCOM)+' '+Time(),"")+'", ' +;
                      '"col011d": "'+DtoC(Date())+' '+Time()+' ", ' +;
                      '"col012d": "", ' +;
                      '"col013c": "NI", ' +;
                      '"col014c": "I"' +;
                      '} '
            _cJson := EncodeUTF8(_cJson, "cp1252")
            _cRet := U_WCRestJson(_cEndPoint,_cResouSB2,_cJson)
            If IsBlind()
               Conout("Integração com PIMS - Inclusão Saldo - Produto: "+AllTrim(SB1->B1_COD)+" Armazem: "+AllTrim(SB2->B2_LOCAL))
               Conout(_cRet)
            EndIf

            SB2->(DbSkip())
         EndDo
      EndIf
   EndIf

   If !IsBlind()
      IncProc("Processando Produtos: "+SB1->B1_COD)
   EndIf

   SB1->(DbSkip())
EndDo

If !_lBat
   MsgInfo("Processo finalizado")
EndIf

Return
