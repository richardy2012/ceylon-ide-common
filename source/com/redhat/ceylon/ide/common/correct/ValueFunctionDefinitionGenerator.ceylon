import ceylon.interop.java {
    CeylonIterable
}

import com.redhat.ceylon.compiler.typechecker.tree {
    Tree
}
import com.redhat.ceylon.ide.common.doc {
    Icons
}
import com.redhat.ceylon.ide.common.platform {
    CommonDocument
}
import com.redhat.ceylon.model.typechecker.model {
    Type,
    TypeParameter,
    ModelUtil {
        isTypeUnknown
    }
}

import java.util {
    ArrayList,
    LinkedHashMap
}

shared class ValueFunctionDefinitionGenerator(
    brokenName, node, rootNode, image, returnType, parameters, 
    isVariable, document)
        extends DefinitionGenerator() {
    
    shared actual String brokenName;
    shared actual Tree.MemberOrTypeExpression node;
    shared actual Tree.CompilationUnit rootNode;
    shared actual Icons image;
    shared actual Type? returnType;
    shared actual LinkedHashMap<String,Type>? parameters;
    Boolean isVariable;
    CommonDocument document;
    
    value isVoid = !returnType exists;
    value isNew 
            = if (is Tree.QualifiedMemberExpression node)
            then node.primary 
                is Tree.BaseTypeExpression |
                   Tree.QualifiedTypeExpression
            else false;
    
    shared actual Boolean isFormalSupported => true;
    
    shared actual String description {
        value params = StringBuilder();
        if (exists parameters) {
            appendParameters(parameters, params);
        }
        return if (isNew) then "constructor 'new " + brokenName + params.string + "'"
            else if (exists parameters) then "'function " + brokenName + params.string + "'"
            else "'value " + brokenName + "'";
    }
    
    shared actual String generateInternal(String indent, 
        String delim, Boolean isFormal) {
        value def = StringBuilder();
        value unit = node.unit;
        if (exists parameters) {
            value typeParams = ArrayList<TypeParameter>();
            value typeParamDef = StringBuilder();
            value typeParamConstDef = StringBuilder();
            appendTypeParams2(typeParams, 
                typeParamDef, typeParamConstDef, 
                returnType);
            appendTypeParams3(typeParams, 
                typeParamDef, typeParamConstDef, 
                parameters.values());
            if (typeParamDef.size > 0) {
                typeParamDef.insert(0, "<");
                typeParamDef.deleteTerminal(1);
                typeParamDef.append(">");
            }
            if (isNew) {
                def.append("new");
            }
            else if (isVoid) {
                def.append("void");
            } else {
                if (isTypeUnknown(returnType)) {
                    def.append("function");
                } else {
                    assert(exists returnType);
                    def.append(returnType.asSourceCodeString(unit));
                }
            }
            def.append(" ")
                .append(brokenName)
                .append(typeParamDef.string);
            appendParameters(parameters, def);
            def.append(typeParamConstDef.string);
            if (isFormal) {
                def.append(";");
            } else if (isVoid||isNew) {
                def.append(" {}");
            } else {
                def.append(" => ")
                    .append(correctionUtil.defaultValue(unit, returnType))
                    .append(";");
            }
        } else {
            if (isVariable) {
                def.append("variable ");
            }
            if (isVoid) {
                def.append("Anything");
            } else {
                if (isTypeUnknown(returnType)) {
                    def.append("value");
                } else {
                    assert(exists returnType);
                    def.append(returnType.asSourceCodeString(unit));
                }
            }
            def.append(" ").append(brokenName);
            if (!isFormal) {
                def.append(" = ")
                    .append(correctionUtil.defaultValue(unit, returnType));
            }
            def.append(";");
        }
        return def.string;
    }
    
    shared actual void generateImports(CommonImportProposals importProposals) {
        importProposals.importType {
            type = returnType;
        };
        if (exists parameters) {
            importProposals.importTypes(CeylonIterable(parameters.values()));
        }
    }
}

class FindValueFunctionVisitor(Tree.MemberOrTypeExpression smte) 
        extends FindArgumentsVisitor(smte) {
    
    shared variable Boolean isVariable = false;
    
    shared actual void visitAssignmentOp(Tree.AssignmentOp that) {
        isVariable = that.leftTerm exists && that.leftTerm == smte;
        super.visitAssignmentOp(that);
    }
    
    shared actual void visitUnaryOperatorExpression(Tree.UnaryOperatorExpression that) {
        isVariable = that.term exists && that.term == smte;
        super.visitUnaryOperatorExpression(that);
    }
    
    shared actual void visitSpecifierStatement(Tree.SpecifierStatement that) {
        isVariable = that.baseMemberExpression exists && that.baseMemberExpression == smte;
        super.visitSpecifierStatement(that);
    }
}

ValueFunctionDefinitionGenerator? createValueFunctionDefinitionGenerator(
    brokenName, node, rootNode, document) {
    
    String brokenName;
    Tree.MemberOrTypeExpression node;
    Tree.CompilationUnit rootNode;
    CommonDocument document;
    
    value isUpperCase 
            = brokenName.first?.uppercase else false;
    if (isUpperCase) {
        return null;
    }
    value fav = FindValueFunctionVisitor(node);
    rootNode.visit(fav);
    value et = fav.expectedType;
    value isVoid = !et exists;
    value returnType 
            = if (isVoid) then null 
            else node.unit.denotableType(et);
    value paramTypes = getParameters(fav);
    
    return if (exists paramTypes) 
    then ValueFunctionDefinitionGenerator(brokenName, node, rootNode,  
            Icons.localMethod, returnType, paramTypes, false, 
            document) 
    else ValueFunctionDefinitionGenerator(brokenName, node, rootNode,
            Icons.localAttribute, returnType, null, fav.isVariable,
            document);
}
