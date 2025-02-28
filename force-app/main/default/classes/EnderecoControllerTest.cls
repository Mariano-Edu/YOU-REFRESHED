@isTest
public class EnderecoControllerTest {
    static final String MENSAGEM_ERRO = String.format(System.Label.ErroConsultarCEP, new List<String>{ 'Not Found', '404' });
    static final String OBJECT_API_NAME = 'Account';
    static final String NOME_CONTA = 'Test Account';
    static final String RUA = 'Rua Antiga';
    static final String CIDADE = 'Cidade Antiga';
    static final String ESTADO = 'Estado Antigo';
    static final String CEP = '01001000';
    static final Map<String, String> ENDERECO = new Map<String, String>{
        'BillingStreet' => RUA,
        'BillingCity' => ViaCEPCalloutMock.LOCALIDADE,
        'BillingState' => ViaCEPCalloutMock.UF,
        'BillingPostalCode' => ViaCEPCalloutMock.CEP
    };

    @TestSetup
    static void makeData() {
        Account conta = new Account(
            Name = NOME_CONTA, 
            BillingStreet = RUA,
            BillingCity = CIDADE,
            BillingState = ESTADO,
            BillingPostalCode = CEP
        );
        insert conta;
    }

    @isTest
    static void testBuscarEnderecoSuccess() {
        EnderecoDTO enderecoEsperado = criarEnderecoEsperado();

        Test.setMock(HttpCalloutMock.class, new ViaCEPCalloutMock(true));
        Test.startTest();

        String resultado = EnderecoController.buscarEndereco(CEP);

        Test.stopTest();

        EnderecoDTO endereco = (EnderecoDTO) JSON.deserialize(resultado, EnderecoDTO.class);

        Assert.areEqual(enderecoEsperado.logradouro, endereco.logradouro, 'Logradouro obtido via CEP.');

        EnderecoService.EnderecoRequest req =  new EnderecoService.EnderecoRequest();
        req.cep = '13332121';
        
        EnderecoService.buscarEnderecoInvocable(new List<EnderecoService.EnderecoRequest>{req});


    }

    @isTest
    static void testObterEnderecoError() {
        Test.setMock(HttpCalloutMock.class, new ViaCEPCalloutMock(false));

        try {
            Test.startTest();

            EnderecoController.buscarEndereco(CEP);

            Test.stopTest();
        } catch (CalloutException e) {
            Assert.areEqual(MENSAGEM_ERRO, e.getMessage(), 'Ocorreu um erro ao buscar CEP.');
        }
    }

    @isTest
    static void testModificarEndereco() {
        Account conta = [SELECT BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode FROM Account LIMIT 1];

        EnderecoController.modificarEndereco(JSON.serialize(ENDERECO), OBJECT_API_NAME, conta.Id);

        Account contaAtualizada = [SELECT BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode FROM Account WHERE Id = :conta.Id];

        Assert.areEqual(RUA, contaAtualizada.BillingStreet, 'Rua mantida.');
        Assert.areEqual(ViaCEPCalloutMock.LOCALIDADE, contaAtualizada.BillingCity, 'Cidade atualizada.');
        Assert.areEqual(ViaCEPCalloutMock.UF, contaAtualizada.BillingState, 'Estado atualizado.');
        Assert.areEqual(ViaCEPCalloutMock.CEP, contaAtualizada.BillingPostalCode, 'CEP atualizado.');
    }

    @isTest
    static void testObterRegistro() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        String registroJSON = EnderecoController.obterRegistro(new List<String>(ENDERECO.keySet()), OBJECT_API_NAME, conta.Id);

        Account contaObtida = (Account) JSON.deserialize(registroJSON, Account.class);

        Assert.areEqual(CIDADE, contaObtida.BillingCity, 'Cidade da conta obtida com sucesso.');
        Assert.areEqual(ESTADO, contaObtida.BillingState, 'Estado da conta obtido com sucesso.');
        Assert.areEqual(CEP, contaObtida.BillingPostalCode, 'CEP da conta obtido com sucesso.');
    }

    static EnderecoDTO criarEnderecoEsperado() {
        return (EnderecoDTO) JSON.deserialize((new ViaCEPCalloutMock(true)).respond(null).getBody(), EnderecoDTO.class);
    }
}