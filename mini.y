%{
    #include <string>
    #include <stdio.h>
    #include <stdlib.h>
    #include <iostream>
    #include <map>

    using namespace std;

    extern "C" int yylex();

    #define YYSTYPE Atributos

    int linha = 1;
    int coluna = 1;

    struct Atributos {
        string v;
        string c;
        int linha;
    };

    int yylex();
    int yyparse();
    void yyerror(const char *);

    void geraPrograma(Atributos a);

    string declaraInt(Atributos s2);
    string geraNomeVar();
    string geraTemp();
    string geraEntrada(Atributos s2);
    string geraSaida(Atributos s2);
    string geraFor(Atributos s2, Atributos s5, Atributos s7, Atributos s9);

    Atributos geraAtribuicao(Atributos s1, Atributos s3);
    Atributos geraAtribuicaoComArray(Atributos s1, Atributos s3, Atributos s6);
    Atributos geraEntradaComArray(Atributos s2, Atributos s4);
    Atributos geraValorComArray(Atributos s1, Atributos s3); 
    Atributos gera_codigo_operacao(Atributos s1, Atributos s2, Atributos s3);
    Atributos gera_codigo_comparacao(Atributos s1, Atributos s2, Atributos s3);
    Atributos gera_codigo_negacao(Atributos s1, Atributos s2);

    int nVar = 0;

    map<string,string> ts;
%}

%start S

%token CINT CDOUBLE TK_ID TK_VAR TK_CONSOLE TK_SHIFTR TK_SHIFTL TK_ENDL
%token TK_FOR TK_IN TK_2PT TK_IF TK_THEN TK_ELSE TK_BEGIN TK_END TK_STRING

%right '!'
%nonassoc "&&" "||"
%nonassoc '<' '>' "<=" "=>"  "==" "!="
%left '+' '-'
%left '*' '/' '%'

%%

S           : CMDS { geraPrograma( $1 ); } 
            ;  

CMDS        : CMDS CMD ';' { $$.c = $1.c + $2.c; }
            | CMD ';' 
            ;
    
CMD         : DECLVAR
            | ENTRADA
            | SAIDA
            | ATR
            | FOR
            | IF
            ;

BLOCO       : TK_BEGIN CMDS TK_END
            | TK_BEGIN TK_END
            | CMDS
            ;
    
DECLVAR     : TK_VAR VARS { declaraInt($2); }
            ;
    
VARS        : VARS ',' VAR { $$.c = $1.c + ", " + $3.c; }
            | VAR
            ;
        
VAR         : TK_ID '[' CINT ']' { $$.c = $1.v + "[" + $3.v + "]"; }
            | TK_ID { $$.c = $1.v; }
            ;
        
ENTRADA     : TK_CONSOLE ENTRADAS          
            ;

ENTRADAS    : TK_SHIFTR TK_ID ENTRADAS { geraEntrada($2); } 
            | TK_SHIFTR TK_ID '[' E ']' ENTRADAS { geraEntradaComArray($2, $4); }
            | TK_SHIFTR TK_ID { geraEntrada($2); }
            | TK_SHIFTR TK_ID '[' E ']' { geraEntradaComArray($2, $4); } 
            ;
  
SAIDA       : TK_CONSOLE SAIDAS TK_ENDL
            | TK_CONSOLE SAIDAS
            ;

SAIDAS      : TK_SHIFTL E SAIDAS { geraSaida($2); }
            | TK_SHIFTL E { geraSaida($2); }
            | TK_SHIFTL TK_STRING SAIDAS { geraSaida($2); }
            | TK_SHIFTL TK_STRING { geraSaida($2); }
            ;
        
FOR         : TK_FOR TK_ID TK_IN '[' E TK_2PT E ']' BLOCO { geraFor($2, $5, $7, $9); }        
            ;
            
IF          : TK_IF E TK_THEN BLOCO TK_ELSE BLOCO ';'
            | TK_IF E TK_THEN BLOCO ';'
            ;
  
ATR         : TK_ID '=' E ';' { geraAtribuicao($1, $3) ; }
            | TK_ID '[' E ']' '=' E ';'{ geraAtribuicaoComArray($1, $3, $6); }
            ;
  
E           : E '+' E { gera_codigo_operacao($1, $2, $3); }
            | E '-' E { gera_codigo_operacao($1, $2, $3); }
            | E '*' E { gera_codigo_operacao($1, $2, $3); }
            | E '/' E { gera_codigo_operacao($1, $2, $3); }
            | E '%' E { gera_codigo_operacao($1, $2, $3); }
            | C
            | L
            | N
            | V
            ;

C           : V '<' V { gera_codigo_operacao($1, $2, $3); }
            | V '>' V { gera_codigo_operacao($1, $2, $3); }
            | V "<=" V { gera_codigo_operacao($1, $2, $3); }
            | V ">=" V { gera_codigo_operacao($1, $2, $3); }
            | V "==" V { gera_codigo_operacao($1, $2, $3); }
            | V "!=" V { gera_codigo_operacao($1, $2, $3); }
            ;

L           : C "&&" C { gera_codigo_operacao($1, $2, $3); }
            | C "||" C { gera_codigo_operacao($1, $2, $3); }
            ;

N           : '!' C
            | '!' L
            | '!' V
            ;
  
V           : TK_ID '[' E ']' { geraValorComArray($1, $3); }
            | TK_ID     { $$.c = $1.c; $$.v = $1.v; }
            | CINT      { $$.c = $1.c; $$.v = $1.v; } 
            | '(' E ')' { $$ = $2; }
            ;

%%

#include "lex.yy.c"

void yyerror( const char* st ){
    puts( st ); 
    printf( "Linha %d, coluna %d, proximo a: %s\n", linha, coluna, yytext );
    exit( 0 );
}

string cabecalho = 
"#include <iostream>\n\n" 
"using namespace std;\n\n"
"int main() {\n";

string fim_programa = 
"  return 0;\n"
"}\n";

void geraPrograma(Atributos a){
  cout << cabecalho
       << a.c 
       << "  cout << " << a.v << ";\n"
       << "  cout << endl;\n"
       << fim_programa
       << endl;
}

string declaraInt(Atributos s2){
    Atributos gerado;

    gerado.c = "int " + s2.c + ";\n";

    return gerado.c;
}

string geraNomeVar(){
    char buf[20] = "";

    sprintf( buf, "t%d", nVar++ );

    return buf;
}

string geraTemp(){
    static int n_var_temp = 0;

    string nome = "t_" + to_string( n_var_temp++ );
    ts[nome] = "  int " + nome + ";\n";

    return nome;
}

string geraEntrada(Atributos s2){
    Atributos gerado;

    gerado.c = "cin >> " + s2.v + ";\n";

    return gerado.c;
}

string geraSaida(Atributos s2){
    Atributos gerado;

    gerado.c = s2.c + "cout << " + s2.v + " << endl;\n";

    return gerado.c;
}

string geraFor(Atributos s2, Atributos s5, Atributos s7, Atributos s9){
    Atributos gerado;

    string cond = geraNomeVar();

    gerado.c = s5.c + s7.c + s2.v + " = " + s5.v + ";\n"
                + "meio: \n" + cond + " = " + s2.v + " > " + s7.v + ";\n"
                + "if( " + cond + ") goto fim;\n"
                + s9.c + s2.v + " = " + s2.v + " + 1;\n"
                + "goto meio;\n"
                + "fim: \n";

    return gerado.c;
}

Atributos geraAtribuicao(Atributos s1, Atributos s3){
    Atributos gerado;

    gerado.v = s3.v;
    gerado.c = s3.c + s1.v + " = " + s3.v + ";\n";

    return gerado;
}

Atributos geraAtribuicaoComArray(Atributos s1, Atributos s3, Atributos s6){
    Atributos gerado;

    gerado.c = s3.c + s6.c + s1.v + "[" + s3.v + "] = " + s6.v  + ";\n";
    gerado.v = s6.v;
    
    return gerado;
}

Atributos geraEntradaComArray(Atributos s2, Atributos s4){
    Atributos gerado;

    gerado.v = geraNomeVar();
    gerado.c = s4.c + "cin >> " + gerado.v + ";\n" + s2.v + "[" + s4.v + "] = " + gerado.v + ";\n";

    return gerado;
}

Atributos geraValorComArray(Atributos s1, Atributos s3){
    Atributos gerado;

    gerado.c = geraNomeVar();
    gerado.v = s3.c + gerado.v + " = " + s1.v + "[" + s3.v + "];\n";

    return gerado;
}

Atributos gera_codigo_operacao(Atributos param1, Atributos opr, Atributos param2){
    Atributos gerado;

    gerado.v = geraTemp();
    gerado.c = param1.c + param2.c + 
                "  " + gerado.v + " = " + param1.v + opr.v + param2.v + ";\n";

    return gerado;
}

Atributos gera_codigo_comparacao(Atributos param1, Atributos opr, Atributos param2){
    Atributos gerado;

    gerado.v = geraTemp();
    gerado.c = param1.c + opr.v + param2.c + ";\n";

    return gerado;
}


Atributos gera_codigo_negacao(Atributos opr, Atributos param){
    Atributos gerado;

    gerado.v = param.v;
    gerado.c = opr.v + param.v + ";\n";

    return gerado;
}

int main(int argc, char* st[]){ 
    yyparse();

    return 0;
}