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

    string geraNomeVar();
    string gera_temp();

    Atributos gera_codigo_operacao(Atributos s1, Atributos s2, Atributos s3);
    Atributos gera_codigo_comparacao(Atributos s1, Atributos s2, Atributos s3);
    Atributos gera_codigo_negacao(Atributos s1, Atributos s2);

    int nVar = 0;

    map<string,string> ts;
%}

%start S

%token CINT CDOUBLE TK_ID TK_VAR TK_CONSOLE TK_SHIFTR TK_SHIFTL TK_ENDL
%token TK_FOR TK_IN TK_2PT TK_IF TK_THEN TK_ELSE TK_BEGIN TK_END TK_RESTO

%right '!'
%nonassoc "&&" "||"
%nonassoc '<' '>' "<=" "=>"  "==" "!="
%left '+' '-'
%left '*' '/'


%%

S           : DECLVAR CMDS
                { cout << $1.c << endl; }
            ;  

CMDS        : CMDS CMD ';' { $$.c = $1.c + $2.c; }
            | CMD ';' 
            ;
    
CMD         : ENTRADA
            | SAIDA
            | ATR
            | FOR
            | IF
            ;

BLOCO       : TK_BEGIN CMDS TK_END
            | TK_BEGIN TK_END
            ;
    
DECLVAR     : TK_VAR VARS 
                { $$.c = "int " + $2.c + ";\n"; }
            ;
    
VARS        : VARS ',' VAR  { $$.c = $1.c + ", " + $3.c; }
            | VAR
            ;
        
VAR         : TK_ID '[' CINT ']'  
                { $$.c = $1.v + "[" + $3.v + "]"; }
            | TK_ID                
                { $$.c = $1.v; }
            ;
        
ENTRADA     : TK_CONSOLE ENTRADAS          
            ;

ENTRADAS    : TK_SHIFTR TK_ID ENTRADAS { $$.c = "cin >> " + $2.v + ";\n"; } 
            | TK_SHIFTR TK_ID '[' E ']' ENTRADAS
                { $$.v = geraNomeVar();
                $$.c = $4.c 
                        + "cin >> " + $$.v + ";\n"
                        + $2.v + "[" + $4.v + "] = " + $$.v + ";\n"; }
            | TK_SHIFTR TK_ID
            | TK_SHIFTR TK_ID '[' E ']'         
            ;
  
SAIDA       : TK_CONSOLE SAIDAS TK_ENDL
            ;

SAIDAS      : TK_SHIFTL E SAIDAS { $$.c = $2.c + "cout << " + $2.v + " << endl;\n"; }
            | TK_SHIFTL E
            ;
        
FOR         : TK_FOR TK_ID TK_IN '[' E TK_2PT E ']' CMD  
                {  string cond = geraNomeVar();
       
                    $$.c = $5.c + $7.c 
                            + $2.v + " = " + $5.v + ";\n"
                            + "meio :\n" + cond + " = " + $2.v + " > " + $7.v + ";\n"
                            + "if( " + cond + ") goto fim;\n"
                            + $9.c
                            + $2.v + " = " + $2.v + " + 1;\n"
                            + "goto meio;\n"
                            + "fim :\n";
            }        
            ;
            
IF          : TK_IF E TK_THEN BLOCO TK_ELSE BLOCO ';'
            | TK_IF E TK_THEN BLOCO ';'
            ;
  
ATR         : TK_ID '=' E ';'
                { $$.v = $3.v;
                    $$.c = $3.c + $1.v + " = " + $3.v + ";\n";
                }
            | TK_ID '[' E ']' '=' E ';'
                { $$.c = $3.c + $6.c 
                        + $1.v + "[" + $3.v + "] = " + $6.v + ";\n";
                    $$.v = $6.v;
                }
            ;
  
E           : E '+' E { gera_codigo_operacao($1, $2, $3); }
            | E '-' E { gera_codigo_operacao($1, $2, $3); }
            | E '*' E { gera_codigo_operacao($1, $2, $3); }
            | E '/' E { gera_codigo_operacao($1, $2, $3); }
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
  
V           : TK_ID '[' E ']' 
                { $$.v = geraNomeVar();
                  $$.c = $3.c + $$.v + " = " + $1.v + "[" + $3.v + "];\n";               
                }
            | TK_ID     { $$.c = ""; $$.v = $1.v; }
            | CINT      { $$.c = ""; $$.v = $1.v; } 
            | '(' E ')' { $$ = $2; }
            | '"' TK_RESTO '"'  
            ;

%%

#include "lex.yy.c"

void yyerror( const char* st ){
    puts( st ); 
    printf( "Linha %d, coluna %d, proximo a: %s\n", linha, coluna, yytext );
    exit( 0 );
}

string geraNomeVar(){
    char buf[20] = "";

    sprintf( buf, "t%d", nVar++ );

    return buf;
}

string gera_temp(){
    static int n_var_temp = 0;

    string nome = "t_" + to_string( n_var_temp++ );
    ts[nome] = "  int " + nome + ";\n";

    return nome;
}

Atributos gera_codigo_operacao( Atributos param1, Atributos opr, Atributos param2 ){
    Atributos gerado;

    gerado.v = gera_temp();
    gerado.c = param1.c + param2.c + 
                "  " + gerado.v + " = " + param1.v + opr.v + param2.v + ";\n";

    return gerado;
}

Atributos gera_codigo_comparacao( Atributos param1, Atributos opr, Atributos param2 ){
    Atributos gerado;

    gerado.v = gera_temp();
    gerado.c = param1.c + opr.v + param2.c + ";\n";

    return gerado;
}


Atributos gera_codigo_negacao( Atributos opr, Atributos param ){
    Atributos gerado;

    gerado.v = param.v;
    gerado.c = opr.v + param.v + ";\n";

    return gerado;
}

int main( int argc, char* st[]){ 
    yyparse();

    return 0;
}