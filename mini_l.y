/*
*	CS 152
*	Project Phase 2
*	Ikk Anmol Singh Hundal  <861134450>
*	Chwan-Hao Tung 			<861052182>
*/

%{
	#include <stdio.h>
	#include <stdlib.h>
    #include <map>
    #include <set>
    #include <string>
    #include <vector>
    #include <stack>
    #include <iostream>
    #include <algorithm>
    #include <sstream>
        
    using namespace std;

	void yyerror(const char *msg);
	int yylex();
	extern int line;
	extern int pos;
	extern FILE * yyin;

    class MiniVal{
        public:
            char type;
            int size;
            MiniVal(char type, int size=0)
            :type(type), size(size){}
    };
    
    vector<string> program_vec;
    map<string, MiniVal> symbol_table;
    vector<string> declarations;
    
    bool reading;

    /* List of defines for generateInstruction() One for each syntax */
    #define OP_VAR_DEC 0
    #define OP_ARR_VAR_DEC 1
    #define OP_COPY_STATEMENT 2
    #define OP_ARR_ACCESS_SRC 3 
    #define OP_ARR_ACCESS_DST 4
    #define OP_STD_IN 5
    #define OP_STD_IN_ARR 6
    #define OP_STD_OUT 7
    #define OP_STD_OUT_ARR 8
    #define OP_ADD 9
    #define OP_SUB 10
    #define OP_MULT 11
    #define OP_DIV 12
    #define OP_MOD 13
    #define OP_LT 14
    #define OP_LTE 15
    #define OP_NEQ 16
    #define OP_EQ 17
    #define OP_GTE 18
    #define OP_GT 19
    #define OP_OR 20
    #define OP_AND 21
    #define OP_NOT 22
    #define OP_LABEL_DEC 23
    #define OP_GOTO 24
    #define OP_IF_GOTO 25
    
    #define ARRAY_VAR 100
    #define NUMBER_VAR 101
    #define IDENT_VAR 102
	
    /*Function prototypes*/
    void checkAndInsertDeclaration(string);
    string generateInstruction( int, string, string, string);
    void addInstruction(int, string, string, string);
    void writeToFile(string);
	

    /* Helper functions */
    string newPredicate();
    void newTemp(string &str);
    string newLabel();
    int predicate = 0;
    int label = 0;
%}


%union{
	int number;
	char* string;
	const char* const_string;
	
	struct attributes
	{
		const char* name;
		char type;
		const char* index;
	};

	
	struct attributes attributes;
}


%error-verbose
%start input
%token PROGRAM
%token BEGIN_PROGRAM
%token END_PROGRAM
%token INTEGER
%token ARRAY
%token OF
%token IF
%token THEN
%token ENDIF
%token ELSE
%token WHILE
%token DO
%token BEGINLOOP
%token ENDLOOP
%token CONTINUE
%token READ
%token WRITE
%token AND
%token OR
%token NOT
%token TRUE
%token FALSE
%token SUB
%token ADD
%token MULT
%token DIV
%token MOD
%token EQ
%token NEQ
%token LT
%token GT
%token LTE
%token GTE
%token SEMICOLON
%token COLON
%token COMMA
%token L_PAREN
%token R_PAREN
%token ASSIGN
%token <number> NUMBER
%token <string> IDENT
%token <string> UNRECOGNIZED
%right ASSIGN
%right COLON
%left OR
%left AND
%right NOT
%left EQ NEQ LT GT LTE GTE
%left SUB ADD
%left MULT DIV MOD
%left L_PAREN R_PAREN

%type<attributes> var
%type<const_string> expression
%type<const_string> multiplicative_exp
%type<const_string> term

%%
			
	input:
		    program_declaration   SEMICOLON   block   END_PROGRAM
                {
                    map<string, MiniVal>::iterator it; 
                    for(it=symbol_table.begin(); it!=symbol_table.end();++it){
                        if(it->second.type == 'I')
                            cout << "\t. " << it->first << endl;
                        else if(it->second.type == 'A')
                            cout << "\t.[] " << it->first << ", " << it->second.size << endl;
                    }
                    for(int i=0; i<(int)program_vec.size();++i)
                        cout << program_vec[i] << endl;
                }
			;

    program_declaration: 
            PROGRAM IDENT
                {
                    symbol_table.insert(pair<string, MiniVal>(string($2), MiniVal('P')) );
                }
            ;            
            
			
	block:     
			declarations   begin_program   statements	{printf("block -> declarations   begin_program   statements\n");}
			;
				
	declarations: 
	        declaration   SEMICOLON declarations		{printf("declarations -> declaration semicolon declarations\n");}
			| declaration   SEMICOLON						{printf("declarations -> declaration semicolon\n");}
			;
			
	declaration:          
	        indentifiers   COLON    INTEGER 
                {
                    while(!declarations.empty()){
                        string x = declarations.back();
                        declarations.pop_back();
                        symbol_table.insert(pair<string, MiniVal>(x, MiniVal('I')) );
                    }
                }
			| indentifiers   COLON    ARRAY   L_PAREN   NUMBER   R_PAREN   OF  INTEGER
                {
                    while(!declarations.empty()){
                        string x = declarations.back();
                        declarations.pop_back();
                        symbol_table.insert(pair<string, MiniVal>(x, MiniVal('A', $5)) );
                    }
                    printf("declaration -> indentifiers colon optional_array intege\n");
                }
			;
	
	indentifiers:
	        IDENT  COMMA	indentifiers    {checkAndInsertDeclaration(string($1));}
			| IDENT							{checkAndInsertDeclaration(string($1));}
			;
			
	statement:
			var   ASSIGN   expression											
				{
					addInstruction(OP_COPY_STATEMENT,string($1.name), $3,"");
				}
			| IF   bool_exp   THEN   statements   ENDIF 	{printf("statement -> if bool_exp then statements optional_else end_if\n");}
			| IF   bool_exp   THEN   statements   ELSE statements   ENDIF 	{printf("statement -> if bool_exp then statements optional_else end_if\n");}
			| WHILE   bool_exp   BEGINLOOP   statements   ENDLOOP 		{printf("statement -> while bool_exp begin_loop statements end_loop\n");}
			| DO   BEGINLOOP   statements   ENDLOOP   WHILE   bool_exp 		{printf("statement -> do begin_loop statements end_loop while bool_exp\n");}
			| READ   vars 													
				{
					reading = true;
				}
			| WRITE   vars 
				{
					reading = false;
				}
			| CONTINUE 															{printf("statement -> continue\n");}
			;
		
	vars:
			var    COMMA    vars 	
				{
					
					/*If we're reading output .< dst*/
					if(reading)
					{
						addInstruction(OP_STD_IN,string($1.name),"","");
					}
					/*Otherwise we're writing*/
					else
					{
						addInstruction(OP_STD_OUT,string($1.name),"","");
					}
				}
			| var 
				{
					/*If we're reading output .< dst*/
					if(reading)
					{
						addInstruction(OP_STD_IN,$1.name,"","");
					}
					/*Otherwise we're writing*/
					else
					{
						addInstruction(OP_STD_OUT,$1.name,"","");
					}
				}
			;
		
	statements:
			statement   SEMICOLON	statements		{printf("statements -> statement semicolon statements\n");}
			| statement   SEMICOLON 					{printf("statements -> statement semicolon\n");}
			;
	
	bool_exp:
			relation_and_exp 	{printf("bool_exp -> relation_and_exp relation_and_exps\n");}
			| relation_and_exp	OR  bool_exp 	{printf("bool_exp -> relation_and_exp relation_and_exps\n");}
			;
			
	relation_and_exp:
			relation_exp    {printf("relation_and_exp -> relation_exp relation_exps\n");}
			| relation_exp  AND relation_and_exp 	{printf("relation_and_exp -> relation_exp relation_exps\n");}
			;
	
	relation_exp:
			expression	comp	expression 			{printf("relation_exp -> expression comp expression\n");}
			| TRUE									{printf("relation_exp -> true\n");}
			| FALSE 								{printf("relation_exp -> false\n");}
			| L_PAREN	bool_exp	R_PAREN 		{printf("relation_exp -> l_paren bool_exp r_paren\n");}
			| NOT expression	comp	expression	{printf("relation_exp -> not expression comp expression\n");}
			| NOT TRUE 								{printf("relation_exp -> not true\n");}
			| NOT FALSE 							{printf("relation_exp -> not false\n"); }
			| NOT L_PAREN   bool_exp   R_PAREN 		{printf("relation_exp -> not l_paren bool_exp r_paren\n");}
			;
			
	comp:
			EQ 					{printf("comp -> equal_to\n");}
			| NEQ 				{printf("comp -> not_equal_to\n");}
			| LT 				{printf("comp -> less_than\n");}
			| GT 				{printf("comp -> greater_than\n");}
			| LTE 	            {printf("comp -> less_than_or_equal_to\n");}
			| GTE	            {printf("comp -> greater_than_or_equal_to\n");}
			;
	
	expression:
			multiplicative_exp
				{
					$$ = $1;
					cout << "Collapsing mult_exp " << $$ << " to expression" << endl;
				}
			| expression    ADD   multiplicative_exp	
				{
					//cout << "PRE TEMP: Collapsing exp and mult_exp " << $1 << " and " << $3 << " to expression " << $$ << endl;
					//string mulexp = $3;
					//cout << "PRE TEMP: $3 is " << $3 << endl;
					
					cout << "Pre Temp $3 is " << $3 << endl;
					cout << "Pre Temp Address of $3 is " << &$3 << endl;
					string temp;
					newTemp(temp);
					cout << "Post Tmp $3 is " << $3 << endl;
					cout << "Post Temp Address of $3 is " << &$3 << endl;
					//string tempk = newTemp();
					//cout << "LiNE 319: TEMP IS " << temp << endl;
					
					symbol_table.insert(pair<string,MiniVal>(temp, MiniVal('I')));
					addInstruction(OP_ADD, temp, $1, $3);
					$$ = temp.c_str();
					cout << "Collapsing exp and mult_exp " << $1 << " and " << $3 << " to expression " << $$ << endl;
				}
			| expression    SUB   multiplicative_exp
				{
					string temp;
					newTemp(temp);
					symbol_table.insert(pair<string,MiniVal>(temp, MiniVal('I')));
					addInstruction(OP_SUB, temp, $1, $3);
					$$ = temp.c_str();
				}
			;
			
	multiplicative_exp:
			term   
				{
					$$ = $1;
					cout << "Collapsing term " << $$ << " to mul_exp" << endl;
				}
			| term MULT  multiplicative_exp
				{
					string temp;
					newTemp(temp);
					symbol_table.insert(pair<string,MiniVal>(temp, MiniVal('I')));
					addInstruction(OP_MULT, temp, $1, $3);
					$$ = temp.c_str();
				}
			| term DIV   multiplicative_exp  
				{
					string temp;
					newTemp(temp);
					symbol_table.insert(pair<string,MiniVal>(temp, MiniVal('I')));
					addInstruction(OP_DIV, temp, $1, $3);
					$$ = temp.c_str();
				}
			| term MOD   multiplicative_exp  
				{
					string temp;
					newTemp(temp);
					symbol_table.insert(pair<string,MiniVal>(temp, MiniVal('I')));
					addInstruction(OP_MOD, temp, $1, $3);
					$$ = temp.c_str();
				}
			;
			
	term:
			var										
				{
					if($1.type == ARRAY_VAR)
					{
						string temp;
						newTemp(temp);
						symbol_table.insert(pair<string,MiniVal>(temp, MiniVal('I')));
						addInstruction(OP_ARR_ACCESS_SRC, temp, $1.name , $1.index);
						$$ = temp.c_str();
					}
					else{
						$$ = $1.name;
						cout << "Collapsing var " << $$ << " to term" << endl;
					}
				}
			| NUMBER								
				{
					cout << "NUMBER IS " << $1 << endl;
					stringstream ss;
					string tmp;
					ss << $1;
					tmp = ss.str();
					$$ = tmp.c_str();
				}
			| L_PAREN   expression R_PAREN			
				{
					$$ = $2;
				}
			| SUB   var
				{
					cout << "Check one" << endl;
					if($2.type == ARRAY_VAR)
					{
						string temp;
						newTemp(temp);
						symbol_table.insert(pair<string,MiniVal>(temp, MiniVal('I')));
						addInstruction(OP_ARR_ACCESS_SRC, temp, $2.name , $2.index);
						addInstruction(OP_SUB, temp, "0" , temp);
						$$ = temp.c_str();
					}
					else
					{
						addInstruction(OP_SUB, $2.name, "0" , $2.name);
						$$= $2.name;
					}
				}
			| SUB   NUMBER
				{
					int t = $2;
					t = -t;
					stringstream ss;
					string tmp;
					ss << t;
					tmp = ss.str();
					$$ = tmp.c_str();
					
				}
			| SUB   L_PAREN   expression R_PAREN
				{
					addInstruction(OP_SUB, $3, "0" , $3);
					$$ = $3;
					
				}
			;
			
	var:
			IDENT
				{
					map<string, MiniVal>::iterator it;
					it = symbol_table.find(string($1));
					/*need to check if array or not, and access index*/
					if(it == symbol_table.end())
					{
						string errstr = "Undeclared variable " + string($1);
						yyerror(errstr.c_str());
						exit(0);

					}
					$$.name = $1;
					$$.type = IDENT_VAR;
					$$.index = NULL;
				}
			| IDENT   L_PAREN   expression   R_PAREN
					{
						/*Need to evaluate expression for index!!! Somehow keep track of value*/
						printf("var -> identifier l_paren expression r_paren\n");
					
						$$.name = $1;
						$$.type = ARRAY_VAR;
						$$.index = $3;
					}
			;

    begin_program:
            BEGIN_PROGRAM {program_vec.push_back(": START");}

%%


int main(int argc, char **argv)
{
   yyparse();
   return 0;
}


void yyerror(const char *msg)
{
   printf("**Line %d %s\n", line, msg);
}


void checkAndInsertDeclaration(string identName){

    if( (find(declarations.begin(), declarations.end(), identName) != declarations.end())
        || (symbol_table.find(identName) != symbol_table.end() )) {
        string errstr = "Multiple Declarations with identifier " + identName;
        yyerror(errstr.c_str());
        exit(0);
    }
    declarations.push_back(identName);

}

/* Given the instruction and operands, fill the value of newNode with the corresponding syntax */

string generateInstruction(int INSTR_VALUE, string op1, string op2="", string op3="")
{
    char instr[254];
    const char * operand1 = op1.c_str();
    const char * operand2 = op2.c_str();
    const char * operand3 = op3.c_str();
	switch(INSTR_VALUE)
	{
		/*Ex: If the instruction is variable declaration*/
		case(OP_VAR_DEC):
		{
			/*Set instr to be ". name", in which name is operand1 */
			sprintf(instr, "\t. %s", operand1);
			break;
		}
		case(OP_ARR_VAR_DEC):
		{
			sprintf(instr, "\t.[] %s, %s", operand1, operand2);
			break;
		}
		case(OP_COPY_STATEMENT):
		{
			sprintf(instr, "\t= %s, %s", operand1, operand2);
			break;
		}
		case(OP_ARR_ACCESS_SRC):
		{
			sprintf(instr, "\t=[] %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_ARR_ACCESS_DST):
		{
			sprintf(instr, "\t[]= %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_STD_IN):
		{
			sprintf(instr, "\t.< %s", operand1);
			break;
		}
		case(OP_STD_IN_ARR):
		{
			sprintf(instr, "\t.[]< %s, %s", operand1, operand2);
			break;
		}
		case(OP_STD_OUT):
		{
			sprintf(instr, "\t.> %s", operand1);
			break;
		}
		case(OP_STD_OUT_ARR):
		{
			sprintf(instr, "\t.[]> %s, %s", operand1, operand2);
			break;
		}
		case(OP_ADD):
		{
			sprintf(instr, "\t+ %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_SUB):
		{
			sprintf(instr, "\t- %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_MULT):
		{
			sprintf(instr, "\t* %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_DIV):
		{
			sprintf(instr, "\t/ %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_MOD):
		{
			sprintf(instr, "\t%% %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_LT):
		{
			sprintf(instr, "\t< %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_LTE):
		{
			sprintf(instr, "\t<= %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_NEQ):
		{
			sprintf(instr, "\t!= %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_EQ):
		{
			sprintf(instr, "\t== %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_GTE):
		{
			sprintf(instr, "\t>= %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_GT):
		{
			sprintf(instr, "\t> %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_OR):
		{
			sprintf(instr, "\t|| %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_AND):
		{
			sprintf(instr, "\t&& %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_NOT):
		{
			sprintf(instr, "\t! %s, %s", operand1, operand2);
			break;
		}
		case(OP_LABEL_DEC):
		{
			sprintf(instr, ": %s", operand1);
			break;
		}
		case(OP_GOTO):
		{
			sprintf(instr, "\t:= %s", operand1);
			break;
		}
		case(OP_IF_GOTO):
		{
			sprintf(instr, "\t?:= %s, %s", operand1, operand2);
			break;
		}
		default:
		{
            cout << "Unknown Operation" << endl;
			exit(0);
			break;
		}
	}
    
    return string(instr);
}


void addInstruction(int INSTRUCTION, string operator1, string operator2, string operator3)
{
	
	string instr = generateInstruction(INSTRUCTION, operator1, operator2, operator3);
    program_vec.push_back(instr);
	return;		 
}


string newLabel()
{
    char tmp[10];
    sprintf(tmp, "L%d", label);
    string ret = string(tmp);
    ++label;
    return ret;
}



void newTemp(string & str)
{
    static int tmp_cnt = 0;
    stringstream ss;
	string tmp;
	ss << tmp_cnt;
	tmp = ss.str();
    str = "t" + tmp;
    ++tmp_cnt;
}


string newPredicate()
{
    char tmp[10];
    sprintf(tmp, "p%d", predicate);
    string ret = string(tmp);
    ++predicate;
	return ret;
}
