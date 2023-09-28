User function APICORREIOS(cCEP)

    local aHeader as array
    local oRest as object
    local nStatus as numeric
    local cError as char
    Local logradouro
	Local complemento
	Local bairro
	Local localidade
	Local uf
    Local tags
    Local nPos
    Local aTags := {}
    Local aRet := {}
    Local i

    aHeader := {}

    // Tags obrigatorias que devem existir no retorno do WS ...
    aAdd(aTags, "LOGRADOURO")
    aAdd(aTags, "COMPLEMENTO")
    aAdd(aTags, "BAIRRO")
    aAdd(aTags, "LOCALIDADE")
    aAdd(aTags, "UF")

    // https://tdn.totvs.com/display/public/framework/FWRest
    oRest := FWRest():New("https://viacep.com.br/ws/") 

    //Endpoint
    oRest:setPath(cCEP + "/json/" )

    //CabeÃ§alho da requisiÃ§Ã£o
    //aAdd(aHeader,"Accept-Encoding: UTF-8")
    //aAdd(aHeader,"Content-Type: application/json; charset=utf-8")

    // Exemplo Objeto JSON com dados que serao enviados caso seja um POST, PUT ...
    // https://jsonplaceholder.typicode.com/guide/
    /*
        jBody := JsonObject():New()
        jBody["title"] := "foo"
        jBody["body"] := "bar"
        jBody["userId"] := 1
    */

    //oRest:SetPostParams(jBody:toJson()) // Passar os dados do POST
    oRest:SetChkStatus(.F.)

    if oRest:Get()
        cError := ""
        nStatus := HTTPGetStatus(@cError)

        if nStatus >= 200 .And. nStatus <= 299
            if Empty(oRest:getResult())
                MsgInfo(nStatus , "GetResult Vazio" )
            else
                oJson := JSonObject():New()
                cErr  := oJSon:fromJson(oRest:getResult())

                If !empty(cErr)
                    MsgStop(cErr,"JSON PARSE ERROR")
                    Return
                Endif

                tags := oJson:GetNames()

                //Procurando pela tag erro ...
                nPos := aScan(tags, {|x| AllTrim(Upper(x)) == "ERRO"})
                If nPos > 0
                    MsgInfo("O CEP informado no cadastro de cliente não consta na base de dados da consulta pública", "WS retornou erro")
                    Return nil
                EndIf     

                // Verificando se possui todas as tags necessarias (LOGRADOURO, MUNICIPO, ETC ...)
                for i := 1 to len(aTags)
                    nPos := aScan(tags, {|x| AllTrim(Upper(x)) == aTags[i]})
                    If nPos == 0
                        MSGINFO( "Falta a tag " + aTags[i] + " no retorno do WS", "Falta de tag retorno WS" )
                        Return nil
                    EndIf 
                next

                // Pegar manualmente o counteudo de um JSON ...
                logradouro  := oJson:GetJSonObject('logradouro')
                complemento := oJson:GetJSonObject('complemento')
                bairro      := oJson:GetJSonObject('bairro')
                localidade  := oJson:GetJSonObject('localidade')
                uf          := oJson:GetJSonObject('uf')

                // OU 
                // pode pegar com oJson['chave'] ...
                aAdd(aRet, oJson['logradouro']) // LOGRADOURO
                aAdd(aRet, oJson['complemento'] ) // COMPLEMENTO
                aAdd(aRet, oJson['bairro'] ) // BAIRRO
                aAdd(aRet, oJson['localidade'] ) // LOCALIDADE
                aAdd(aRet, oJson['uf'] ) //UF
                aAdd(aRet, logradouro + " " + complemento + " " + bairro + " " + localidade + " " + uf ) // ENDERECO_COMPLETO

                return aRet
            endif
        else
            MsgStop(cError)
        endif
    else
        MsgStop(oRest:getLastError() + CRLF + oRest:getResult())
    endif

return nil
