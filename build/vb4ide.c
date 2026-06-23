#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <math.h>

/* Sage AOT Runtime */
typedef struct { int type; union { double number; int boolean; const char* string; void* ptr; } as; } SageValue;
enum { SAGE_NIL=0, SAGE_NUM=1, SAGE_BOOL=2, SAGE_STR=3 };
static SageValue sage_number(double n) { SageValue v; v.type=SAGE_NUM; v.as.number=n; return v; }
static SageValue sage_bool(int b) { SageValue v; v.type=SAGE_BOOL; v.as.boolean=b; return v; }
static SageValue sage_string(const char* s) { SageValue v; v.type=SAGE_STR; v.as.string=s; return v; }
static SageValue sage_nil(void) { SageValue v; v.type=SAGE_NIL; return v; }
static int sage_truthy(SageValue v) { if(v.type==SAGE_NIL) return 0; if(v.type==SAGE_BOOL) return v.as.boolean; if(v.type==SAGE_NUM) return v.as.number!=0.0; return 1; }
static SageValue sage_str(SageValue v);  /* forward decl */
static SageValue sage_strcat(SageValue a, SageValue b);  /* forward decl */
static SageValue sage_add(SageValue a, SageValue b) { if(a.type==SAGE_NUM&&b.type==SAGE_NUM) return sage_number(a.as.number+b.as.number); if(a.type==SAGE_STR&&b.type==SAGE_STR) return sage_strcat(a,b); if(a.type==SAGE_STR||b.type==SAGE_STR){SageValue sa=sage_str(a),sb=sage_str(b);return sage_strcat(sa,sb);} return sage_nil(); }
static SageValue sage_sub(SageValue a, SageValue b) { return sage_number(a.as.number-b.as.number); }
static SageValue sage_mul(SageValue a, SageValue b) { return sage_number(a.as.number*b.as.number); }
static SageValue sage_div(SageValue a, SageValue b) { return sage_number(a.as.number/b.as.number); }
static SageValue sage_mod(SageValue a, SageValue b) { return sage_number(fmod(a.as.number,b.as.number)); }
static SageValue sage_eq(SageValue a, SageValue b) { if(a.type!=b.type) return sage_bool(0); if(a.type==SAGE_NIL) return sage_bool(1); if(a.type==SAGE_BOOL) return sage_bool(a.as.boolean==b.as.boolean); if(a.type==SAGE_NUM) return sage_bool(a.as.number==b.as.number); if(a.type==SAGE_STR) return sage_bool(strcmp(a.as.string,b.as.string)==0); return sage_bool(0); }
static SageValue sage_neq(SageValue a, SageValue b) { return sage_bool(!sage_eq(a,b).as.boolean); }
static SageValue sage_gt(SageValue a, SageValue b) { return sage_bool(a.as.number>b.as.number); }
static SageValue sage_lt(SageValue a, SageValue b) { return sage_bool(a.as.number<b.as.number); }
static SageValue sage_strcat(SageValue a, SageValue b) { if(a.type!=SAGE_STR||b.type!=SAGE_STR) return sage_nil(); size_t la=strlen(a.as.string),lb=strlen(b.as.string); char* r=malloc(la+lb+1); memcpy(r,a.as.string,la); memcpy(r+la,b.as.string,lb); r[la+lb]=0; SageValue v; v.type=SAGE_STR; v.as.string=r; return v; }

enum { SAGE_ARR=4, SAGE_DICT=5, SAGE_TUPLE=6 };
typedef struct { SageValue* elems; int count; int cap; } SageArr;
typedef struct { char** keys; SageValue* vals; int count; int cap; } SageDict;
static SageValue sage_array(int n, ...) { SageArr* a=malloc(sizeof(SageArr)); a->cap=n>4?n:4; a->count=n; a->elems=malloc(sizeof(SageValue)*a->cap); va_list ap; va_start(ap,n); for(int i=0;i<n;i++) a->elems[i]=va_arg(ap,SageValue); va_end(ap); SageValue v; v.type=SAGE_ARR; v.as.ptr=a; return v; }
static int sage_array_len(SageValue v) { if(v.type==SAGE_ARR) return ((SageArr*)v.as.ptr)->count; return 0; }
static SageValue sage_array_get(SageValue v, int i) { if(v.type==SAGE_ARR || v.type==SAGE_TUPLE){SageArr*a=(SageArr*)v.as.ptr; if(i>=0&&i<a->count) return a->elems[i];} return sage_nil(); }
static SageValue sage_index(SageValue c, SageValue i) { if(c.type==SAGE_ARR || c.type==SAGE_TUPLE) return sage_array_get(c,(int)i.as.number); if(c.type==SAGE_DICT){SageDict*d=(SageDict*)c.as.ptr; if(i.type==SAGE_STR) for(int k=0;k<d->count;k++) if(strcmp(d->keys[k],i.as.string)==0) return d->vals[k];} return sage_nil(); }
static SageValue sage_index_set(SageValue c, SageValue i, SageValue val) { if(c.type==SAGE_ARR){SageArr*a=(SageArr*)c.as.ptr; int idx=(int)i.as.number; if(idx>=0&&idx<a->count) a->elems[idx]=val;} if(c.type==SAGE_DICT){SageDict*d=(SageDict*)c.as.ptr; if(i.type==SAGE_STR){for(int k=0;k<d->count;k++) if(strcmp(d->keys[k],i.as.string)==0){d->vals[k]=val;return val;} if(d->count>=d->cap){d->cap=d->cap?d->cap*2:4;d->keys=realloc(d->keys,sizeof(char*)*d->cap);d->vals=realloc(d->vals,sizeof(SageValue)*d->cap);}d->keys[d->count]=strdup(i.as.string);d->vals[d->count]=val;d->count++;}} return val; }
static SageValue sage_dict(int n, ...) { SageDict*d=calloc(1,sizeof(SageDict)); d->cap=n>2?n:2; d->keys=malloc(sizeof(char*)*d->cap); d->vals=malloc(sizeof(SageValue)*d->cap); va_list ap; va_start(ap,n); for(int i=0;i<n;i++){d->keys[i]=strdup(va_arg(ap,const char*));d->vals[i]=va_arg(ap,SageValue);d->count++;} va_end(ap); SageValue v; v.type=SAGE_DICT; v.as.ptr=d; return v; }
static SageValue sage_tuple(int n, ...) { SageArr*a=malloc(sizeof(SageArr)); a->cap=n; a->count=n; a->elems=malloc(sizeof(SageValue)*n); va_list ap; va_start(ap,n); for(int i=0;i<n;i++) a->elems[i]=va_arg(ap,SageValue); va_end(ap); SageValue v; v.type=SAGE_TUPLE; v.as.ptr=a; return v; }
static SageValue sage_slice(SageValue c, SageValue s, SageValue e) { if(c.type!=SAGE_ARR) return sage_nil(); SageArr*a=(SageArr*)c.as.ptr; int si=(int)s.as.number,ei=e.type==SAGE_NIL?a->count:(int)e.as.number; if(si<0)si=0;if(ei>a->count)ei=a->count; int n=ei-si;if(n<0)n=0; return sage_array(0); /* simplified */ }
static void sage_push(SageValue arr, SageValue val) { if(arr.type==SAGE_ARR){SageArr*a=(SageArr*)arr.as.ptr;if(a->count>=a->cap){a->cap=a->cap?a->cap*2:4;a->elems=realloc(a->elems,sizeof(SageValue)*a->cap);}a->elems[a->count++]=val;} }
static SageValue sage_pop(SageValue arr) { if(arr.type==SAGE_ARR){SageArr*a=(SageArr*)arr.as.ptr;if(a->count>0)return a->elems[--a->count];} return sage_nil(); }
static SageValue sage_len(SageValue v) { if(v.type==SAGE_ARR) return sage_number(((SageArr*)v.as.ptr)->count); if(v.type==SAGE_STR) return sage_number(strlen(v.as.string)); if(v.type==SAGE_DICT) return sage_number(((SageDict*)v.as.ptr)->count); return sage_number(0); }
static SageValue sage_range(int n) { SageArr*a=malloc(sizeof(SageArr)); a->cap=n>4?n:4; a->count=n; a->elems=malloc(sizeof(SageValue)*a->cap); for(int i=0;i<n;i++) a->elems[i]=sage_number(i); SageValue v; v.type=SAGE_ARR; v.as.ptr=a; return v; }
static SageValue sage_get_property(SageValue obj, const char* name) { if(obj.type==SAGE_DICT){SageDict*d=(SageDict*)obj.as.ptr; for(int i=0;i<d->count;i++) if(strcmp(d->keys[i],name)==0) return d->vals[i];} return sage_nil(); }
static SageValue sage_dict_keys(SageValue d) { if(d.type!=SAGE_DICT) return sage_array(0); SageDict*dd=(SageDict*)d.as.ptr; SageArr*a=malloc(sizeof(SageArr)); a->cap=dd->count>4?dd->count:4; a->count=dd->count; a->elems=malloc(sizeof(SageValue)*a->cap); for(int i=0;i<dd->count;i++) a->elems[i]=sage_string(dd->keys[i]); SageValue v; v.type=SAGE_ARR; v.as.ptr=a; return v; }
static SageValue sage_str(SageValue v) { char buf[256]; switch(v.type){case SAGE_NUM:{double d=v.as.number;if(d==(double)(long long)d&&d>=-1e15&&d<=1e15)snprintf(buf,sizeof(buf),"%lld",(long long)d);else snprintf(buf,sizeof(buf),"%g",d);break;}case SAGE_STR:return v;case SAGE_BOOL:return sage_string(v.as.boolean?"true":"false");default:return sage_string("nil");}return sage_string(strdup(buf));}
static SageValue sage_tonumber(SageValue v) { if(v.type==SAGE_NUM)return v; if(v.type==SAGE_STR)return sage_number(atof(v.as.string)); return sage_number(0);}
static SageValue sage_type(SageValue v) { switch(v.type){case SAGE_NUM:return sage_string("number");case SAGE_STR:return sage_string("string");case SAGE_BOOL:return sage_string("bool");case SAGE_ARR:return sage_string("array");case SAGE_DICT:return sage_string("dict");default:return sage_string("nil");} }
static void sage_print_value(SageValue v) { switch(v.type) { case SAGE_NUM: { double d=v.as.number; if(d==(double)(long long)d&&d>=-1e15&&d<=1e15) printf("%lld",(long long)d); else printf("%g",d); break; } case SAGE_BOOL: fputs(v.as.boolean?"true":"false",stdout); break; case SAGE_STR: fputs(v.as.string,stdout); break; case SAGE_ARR: { SageArr*a=(SageArr*)v.as.ptr; printf("["); for(int i=0;i<a->count;i++){if(i)printf(", ");sage_print_value(a->elems[i]);} printf("]"); break; } case SAGE_DICT: { SageDict*d=(SageDict*)v.as.ptr; printf("{"); for(int i=0;i<d->count;i++){if(i)printf(", ");printf("\"%s\": ",d->keys[i]);sage_print_value(d->vals[i]);} printf("}"); break; } default: fputs("nil",stdout); } }

static SageValue s_show_banner(int argc, SageValue* argv);
static SageValue s_run_file(int argc, SageValue* argv);
static SageValue s_run_ide(int argc, SageValue* argv);
static SageValue s_main(int argc, SageValue* argv);

static SageValue s_show_banner(int argc, SageValue* argv) {
    sage_print_value(sage_strcat(sage_strcat(sage_string("VisualBasicSage v"), s_VERSION), sage_string(" - VB4 Compatible IDE & Runtime"))); printf("\n");
    sage_print_value(sage_string("")); printf("\n");
    return sage_nil();
}

static SageValue s_run_file(int argc, SageValue* argv) {
    SageValue s_path = (argc > 0) ? argv[0] : sage_nil();
    SageValue s_source = sage_nil() /* unsupported call: sage_get_property(s_io, "readfile") */;
    if (sage_truthy(sage_eq(s_source, sage_nil()))) {
        sage_print_value(sage_add(sage_string("Error: could not read "), s_path)); printf("\n");
        return sage_number(1);
    }
    SageValue s_tokens = sage_nil() /* unsupported call: sage_get_property(s_lx, "lex") */;
    SageValue s_tree = sage_nil() /* unsupported call: sage_get_property(s_pr, "parse") */;
    if (sage_truthy(sage_eq(s_tree, sage_nil()))) {
        sage_print_value(sage_string("Error: parse failed")); printf("\n");
        return sage_number(1);
    }
    SageValue s_interp = sage_nil() /* unsupported call: sage_get_property(s_ri, "Interpreter") */;
    sage_nil() /* unsupported call: sage_get_property(s_interp, "execute") */;
    return sage_number(0);
    return sage_nil();
}

static SageValue s_run_ide(int argc, SageValue* argv) {
    sage_print_value(sage_string("Starting IDE (headless mode)...")); printf("\n");
    SageValue s_shell = sage_nil() /* unsupported call: sage_get_property(s_sh, "IdeShell") */;
    sage_nil() /* unsupported call: sage_get_property(s_shell, "new_project") */;
    sage_nil() /* unsupported call: sage_get_property(s_shell, "show_status") */;
    sage_print_value(sage_string("")); printf("\n");
    sage_print_value(sage_string("Commands: new, open <file>, run, stop, exit")); printf("\n");
    sage_print_value(sage_string("")); printf("\n");
    while (sage_truthy(sage_bool(1))) {
        SageValue s_line = sage_nil() /* unsupported call: sage_get_property(s_strings, "strip") */;
        if (sage_truthy((sage_truthy(sage_eq(s_line, sage_string("exit"))) ? sage_eq(s_line, sage_string("exit")) : sage_eq(s_line, sage_string("quit"))))) {
            break;
        } else {
            if (sage_truthy(sage_nil() /* unsupported call: sage_get_property(s_strings, "startswith") */)) {
                SageValue s_path = sage_nil() /* unsupported call: sage_get_property(s_strings, "strip") */;
                sage_nil() /* unsupported call: sage_get_property(s_shell, "open_project") */;
            } else {
                if (sage_truthy(sage_eq(s_line, sage_string("new")))) {
                    sage_nil() /* unsupported call: sage_get_property(s_shell, "new_project") */;
                } else {
                    if (sage_truthy(sage_eq(s_line, sage_string("run")))) {
                        sage_nil() /* unsupported call: sage_get_property(s_shell, "run_project") */;
                    } else {
                        if (sage_truthy(sage_eq(s_line, sage_string("stop")))) {
                            sage_nil() /* unsupported call: sage_get_property(s_shell, "stop_project") */;
                        } else {
                            if (sage_truthy(sage_eq(s_line, sage_string("")))) {
                            } else {
                                sage_print_value(sage_add(sage_string("Unknown command: "), s_line)); printf("\n");
                            }
                        }
                    }
                }
            }
        }
    }
    return sage_nil();
}

static SageValue s_main(int argc, SageValue* argv) {
    SageValue s_args = (argc > 0) ? argv[0] : sage_nil();
    ({ SageValue _args[1]; s_show_banner(0, _args); });
    if (sage_truthy(sage_eq(sage_len(s_args), sage_number(0)))) {
        sage_print_value(sage_string("Usage: sage main.sage [command]")); printf("\n");
        sage_print_value(sage_string("")); printf("\n");
        sage_print_value(sage_string("Commands:")); printf("\n");
        sage_print_value(sage_string("  run <file>     Run a VB4 source file")); printf("\n");
        sage_print_value(sage_string("  ide            Start the IDE (headless)")); printf("\n");
        sage_print_value(sage_string("  version        Show version")); printf("\n");
        return sage_number(0);
    }
    SageValue s_cmd = sage_index(s_args, sage_number(0));
    if (sage_truthy(sage_eq(s_cmd, sage_string("run")))) {
        if (sage_truthy(sage_lt(sage_len(s_args), sage_number(2)))) {
            sage_print_value(sage_string("Usage: sage main.sage run <file>")); printf("\n");
            return sage_number(1);
        }
        return ({ SageValue _args[1]; _args[0] = sage_index(s_args, sage_number(1)); s_run_file(1, _args); });
    } else {
        if (sage_truthy(sage_eq(s_cmd, sage_string("ide")))) {
            ({ SageValue _args[1]; s_run_ide(0, _args); });
            return sage_number(0);
        } else {
            if (sage_truthy(sage_eq(s_cmd, sage_string("version")))) {
                sage_print_value(s_VERSION); printf("\n");
                return sage_number(0);
            } else {
                sage_print_value(sage_add(sage_string("Unknown command: "), s_cmd)); printf("\n");
                return sage_number(1);
            }
        }
    }
    return sage_nil();
}

int main(void) {
    /* import compiler.lexer */
    /* import compiler.parser */
    /* import runtime.interpreter */
    /* import runtime.builtins */
    /* import ide.shell */
    /* import strings */
    /* import io */
    /* import sys */
    SageValue s_VERSION = sage_string("0.1.0");
    SageValue s_all_args = sage_nil() /* unsupported call: sage_get_property(s_sys, "args") */;
    SageValue s_script_args = sage_array(0);
    if (sage_truthy(sage_gt(sage_len(s_all_args), sage_number(2)))) {
        SageValue s_i = sage_number(2);
        while (sage_truthy(sage_lt(s_i, sage_len(s_all_args)))) {
            (sage_push(s_script_args, sage_index(s_all_args, s_i)), sage_nil());
            (s_i = sage_add(s_i, sage_number(1)));
        }
    }
    ({ SageValue _args[1]; _args[0] = s_script_args; s_main(1, _args); });
    return 0;
}
