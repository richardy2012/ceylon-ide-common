import com.redhat.ceylon.compiler.typechecker.tree {
    Visitor,
    Node,
    Tree
}

class FindOccurrenceLocationVisitor(Integer offset, Node node) 
        extends Visitor() {
    
    shared variable OccurrenceLocation? occurrence = null;
    variable Boolean inTypeConstraint = false;
    
    actual
    shared void visitAny(Node that) {
        if (inBounds(that))  {
            super.visitAny(that);
        }
        //otherwise, as a performance optimization
        //don't go any further down this branch
    }
    
    actual
    shared void visit(Tree.Condition that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iEXPRESSION;
        }
        super.visit(that);
    }
    
    actual
    shared void visit(Tree.ExistsCondition that) {
        super.visit(that);
        if (exists var = that.variable) {
            value isInBounds 
                    = if (is Tree.Variable var) 
                    then inBounds(var.identifier) 
                    else inBounds(that);
            if (isInBounds) {
                occurrence = OccurrenceLocation.\iEXISTS;
            }
        }
    }
    
    actual
    shared void visit(Tree.ConditionList that) {
        if (inBounds(that)) {
            value conditions = that.conditions;
            if (!conditions.empty) {
                value size = conditions.size();
                for (i in 1..size) {
                    value current = conditions.get(i-1);
                    value next = i<size then conditions.get(i);
                    if (current.endToken == current.token,
                        current.endIndex.intValue()<offset,
                        if (exists next) 
                        then next.startIndex.intValue()>offset 
                        else true) {
                        switch (current)
                        case (is Tree.ExistsCondition) {
                            occurrence = OccurrenceLocation.\iEXISTS;
                        }
                        case (is Tree.NonemptyCondition) {
                            occurrence = OccurrenceLocation.\iNONEMPTY;
                        }
                        case (is Tree.IsCondition) {
                            occurrence = OccurrenceLocation.\iIS;
                        }
                        else {
                            continue;
                        }
                        return;
                    }
                }
            }
        }
        super.visit(that);
    }
    
    actual
    shared void visit(Tree.NonemptyCondition that) {
        super.visit(that);
        if (exists var = that.variable) {
            value isInBounds 
                    = if (is Tree.Variable var) 
                    then inBounds(var.identifier) 
                    else inBounds(that);
            if (isInBounds) {
                occurrence = OccurrenceLocation.\iNONEMPTY;
            }
        }
    }
    
    actual
    shared void visit(Tree.IsCondition that) {
        super.visit(that);
        Boolean isInBounds;
        if (exists var = that.variable) {
            isInBounds = inBounds(var.identifier);
        }
        else if (exists type = that.type) {
            isInBounds = inBounds(that) 
                    && offset>type.endIndex.intValue();
        }
        else {
            isInBounds = false;
        }
        if (isInBounds) {
            occurrence = OccurrenceLocation.\iIS;
        }
    }
    
    actual shared void visit(Tree.TypeConstraint that) {
        inTypeConstraint=true;
        super.visit(that);
        inTypeConstraint=false;
    }
    
    actual shared void visit(Tree.ImportMemberOrTypeList that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iIMPORT;
        }
        super.visit(that);
    }
    
    actual shared void visit(Tree.ExtendedType that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iEXTENDS;
        }
        super.visit(that);
    }
    
    actual shared void visit(Tree.DelegatedConstructor that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iEXTENDS;
        }
        super.visit(that);
    }
    
    actual shared void visit(Tree.SatisfiedTypes that) {
        if (inBounds(that)) {
            occurrence = if (inTypeConstraint) 
                then OccurrenceLocation.\iUPPER_BOUND 
                else OccurrenceLocation.\iSATISFIES;
        }
        super.visit(that);
    }
    
    actual shared void visit(Tree.CaseTypes that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iOF;
        }
        super.visit(that);
    }
    
    actual shared void visit(Tree.CatchClause that) {
        if (inBounds(that) && 
            !inBounds(that.block)) {
            occurrence = OccurrenceLocation.\iCATCH;
        }
        else {
            super.visit(that);
        }
    }
    
    actual shared void visit(Tree.CaseItem that) {
        if (inBounds(that),
            !that.mainEndToken exists ||
            offset<that.endIndex.intValue()) {
            occurrence = OccurrenceLocation.\iCASE;
        }
        super.visit(that);
    }
    
    actual
    shared void visit(Tree.BinaryOperatorExpression that) {
        Tree.Term right = that.rightTerm else that;
        Tree.Term left = that.leftTerm else that;
        
        if (inBounds(left, right)) {
            occurrence = OccurrenceLocation.\iEXPRESSION;
        }
        super.visit(that);
    }
    
    actual
    shared void visit(Tree.UnaryOperatorExpression that) {
        Tree.Term term = that.term else that;

        if (inBounds(that, term) || inBounds(term, that)) {
            occurrence = OccurrenceLocation.\iEXPRESSION;
        }
        super.visit(that);
    }
    
    actual
    shared void visit(Tree.ParameterList that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iPARAMETER_LIST;
        }
        super.visit(that);
    }
    
    actual
    shared void visit(Tree.TypeParameterList that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iTYPE_PARAMETER_LIST;
        }
        super.visit(that);
    }
    
    actual
    shared void visit(Tree.TypeSpecifier that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iTYPE_ALIAS;
        }
        super.visit(that);
    }
    
    actual
    shared void visit(Tree.ClassSpecifier that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iCLASS_ALIAS;
        }
        super.visit(that);
    }
    
    actual
    shared void visit(Tree.SpecifierOrInitializerExpression that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iEXPRESSION;
        }
        super.visit(that);
    }
    
    actual
    shared void visit(Tree.ArgumentList that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iEXPRESSION;
        }
        super.visit(that);
    }
    
    actual
    shared void visit(Tree.TypeArgumentList that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iTYPE_ARGUMENT_LIST;
        }
        super.visit(that);
    }
    
    actual
    shared void visit(Tree.QualifiedMemberOrTypeExpression that) {
        if (inBounds(that.memberOperator, that.identifier)) {
            occurrence = OccurrenceLocation.\iEXPRESSION;
        }
        else {
            super.visit(that);
        }
    }
    
    actual
    shared void visit(Tree.Declaration that) {
        if (inBounds(that)) {
            if (exists o = occurrence, o != OccurrenceLocation.\iPARAMETER_LIST) {
                occurrence=null;
            }
        }
        super.visit(that);
    }
    
    actual shared void visit(Tree.MetaLiteral that) {
        super.visit(that);
        if (inBounds(that)) {
            if (exists o = occurrence, o != OccurrenceLocation.\iTYPE_ARGUMENT_LIST) {
                occurrence = switch (that.nodeType)
                    case ("ModuleLiteral") OccurrenceLocation.\iMODULE_REF 
                    case ("PackageLiteral") OccurrenceLocation.\iPACKAGE_REF 
                    case ("ValueLiteral") OccurrenceLocation.\iVALUE_REF 
                    case ("FunctionLiteral") OccurrenceLocation.\iFUNCTION_REF 
                    case ("InterfaceLiteral") OccurrenceLocation.\iINTERFACE_REF 
                    case ("ClassLiteral") OccurrenceLocation.\iCLASS_REF 
                    case ("TypeParameterLiteral") OccurrenceLocation.\iTYPE_PARAMETER_REF 
                    case ("AliasLiteral") OccurrenceLocation.\iALIAS_REF
                    else OccurrenceLocation.\iMETA;
            }
        }
    }
    
    actual shared void visit(Tree.StringLiteral that) {
        if (inBounds(that)) {
            occurrence = OccurrenceLocation.\iDOCLINK;
        }
    }
    
    actual shared void visit(Tree.DocLink that) {
        if (is Tree.DocLink node) {
            occurrence = OccurrenceLocation.\iDOCLINK;
        }
    }
    
    Boolean inBounds(Node? left, Node? right = left) {
        if (exists startIndex = left?.startIndex?.intValue(), 
            exists stopIndex = right?.endIndex?.intValue()) {
            return startIndex <= node.startIndex.intValue() && 
                    stopIndex >= node.endIndex.intValue();
        }
        else {
            return false;
        }
    }
}