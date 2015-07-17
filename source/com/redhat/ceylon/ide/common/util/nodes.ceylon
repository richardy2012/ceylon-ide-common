import com.redhat.ceylon.compiler.typechecker.tree {
	Node,
	Tree
}
import com.redhat.ceylon.model.typechecker.model {
	Referenceable,
	Parameter,
    Unit,
    ModelUtil,
    Type
}
import ceylon.interop.java {
	CeylonList,
    CeylonIterable,
    javaString
}
import ceylon.collection {
    HashSet,
    MutableSet
}
import java.util.regex {
    Pattern
}

shared object nodes {

    value idPattern = Pattern.compile("(^|[A-Z])([A-Z]*)([_a-z]+)");
    value keywords = ["import", "assert",
        "alias", "class", "interface", "object", "given", "value", "assign", "void", "function", 
        "assembly", "module", "package", "of", "extends", "satisfies", "abstracts", "in", "out", 
        "return", "break", "continue", "throw", "if", "else", "switch", "case", "for", "while", 
        "try", "catch", "finally", "this", "outer", "super", "is", "exists", "nonempty", "then",
        "dynamic", "new", "let"];
    
    shared Node? getReferencedNode(Referenceable? model) {
        if (exists model) {
            if (is Unit unit = model.unit) {
                
            }
        }
        
        return null;
    }
    
    shared Tree.Statement? findStatement(Tree.CompilationUnit cu, Node node) {
        value fsv = FindStatementVisitor(node, false);
        cu.visit(fsv);
        return fsv.statement;
    }

    shared Tree.Statement? findTopLebelStatement(Tree.CompilationUnit cu, Node node) {
        value fsv = FindStatementVisitor(node, true);
        cu.visit(fsv);
        return fsv.statement;
    }
    
	shared Node? findNode(Tree.CompilationUnit cu, Integer offset) {
		FindNodeVisitor visitor = FindNodeVisitor(offset, offset + 1);
		
		cu.visit(visitor);
		
		return visitor.node;
	}
	
	shared Referenceable? getReferencedDeclaration(Node node, Tree.CompilationUnit rn) {
		//NOTE: this must accept a null node, returning null!
		if (is Tree.MemberOrTypeExpression node) {
			return node.declaration;
		} 
		else if (is Tree.SimpleType node) {
			return node.declarationModel;
		} 
		else if (is Tree.ImportMemberOrType node) {
			return node.declarationModel;
		} 
		else if (is Tree.Declaration node) {
			return node.declarationModel;
		} 
		else if (is Tree.NamedArgument node) {
			Parameter? p = node.parameter;
			if (exists p) {
				return p.model;
			}
		}
		else if (is Tree.InitializerParameter node) {
			Parameter? p = node.parameterModel;
			if (exists p) {
				return p.model;
			}
		}
		else if (is Tree.MetaLiteral node) {
			return node.declaration;
		}
		else if (is Tree.SelfExpression node) {
			return node.declarationModel;
		}
		else if (is Tree.Outer node) {
			return node.declarationModel;
		}
		else if (is Tree.Return node) {
			return node.declaration;
		}
		else if (is Tree.DocLink node) {
			value qualified = CeylonList(node.qualified);
			if (!qualified.empty) {
				return qualified.last;
			}
			else {
				return node.base;
			}
		}
		else if (is Tree.ImportPath node) {
			return node.model;
		}

		return null;
	}
	
	shared void appendParameters(StringBuilder result, Tree.FunctionArgument fa, Unit unit, String toString(Node node)) {
		for (pl in CeylonIterable(fa.parameterLists)) {
			result.append("(");
			variable Boolean first = true;
			
			for (p in CeylonIterable(pl.parameters)) {
				if (first) {
					first = false;
				} else {
					result.append(", ");
				}
				
				if (is Tree.InitializerParameter p) {
					if (!ModelUtil.isTypeUnknown(p.parameterModel.type)) {
						result.append(p.parameterModel.type.asSourceCodeString(unit)).append(" ");
					}
				}
				result.append(toString(p));
			}
			result.append(")");
		}
	}
	
	shared Integer getNodeStartOffset(Node? node) {
		return node?.startIndex?.intValue() else 0;
	}
	
	shared Integer getNodeEndOffset(Node? node) {
		return (node?.stopIndex?.intValue() else -1) + 1;
	}

    shared String[] nameProposals(Node node, Boolean unplural = false) {
        value myNode = if (is Tree.FunctionArgument node, exists e = node.expression) then e else node;
        MutableSet<String> names = HashSet<String>();
        variable Node identifyingNode = myNode;
        
        if (is Tree.Expression n = identifyingNode) {
            identifyingNode = n.term;
        }
        if (is Tree.InvocationExpression n = identifyingNode) {
            identifyingNode = n.primary;
        }
        
        if (is Tree.QualifiedMemberOrTypeExpression qmte = identifyingNode, 
                exists decl = qmte.declaration) {
            addNameProposals(names, false, decl.name);
            //TODO: propose a compound name like personName for person.name
        }
        if (is Tree.FunctionType tf = identifyingNode, is Tree.SimpleType type = tf.returnType) {
            addNameProposals(names, false, type.declarationModel.name);
        }
        if (is Tree.BaseMemberOrTypeExpression bmte = identifyingNode, unplural) {
            value name = bmte.declaration.name;
            if (name.endsWith("s") && name.size > 1) {
                addNameProposals(names, false, name.spanTo(name.size - 2));
            }
        }
        
        if (is Tree.SumOp n=identifyingNode) {
            names.add ("sum");
        } else if (is Tree.DifferenceOp n=identifyingNode) {
            names.add ("difference");
        } else if (is Tree.ProductOp n=identifyingNode) {
            names.add ("product");
        } else if (is Tree.QuotientOp n=identifyingNode) {
            names.add ("ratio");
        } else if (is Tree.RemainderOp n=identifyingNode) {
            names.add ("remainder");
        } else if (is Tree.UnionOp n=identifyingNode) {
            names.add ("union");
        } else if (is Tree.IntersectionOp n=identifyingNode) {
            names.add ("intersection");
        } else if (is Tree.ComplementOp n=identifyingNode) {
            names.add ("complement");
        } else if (is Tree.RangeOp n=identifyingNode) {
            names.add ("range");
        } else if (is Tree.EntryOp n=identifyingNode) {
            names.add ("entry");
        }

        if (is Tree.Term term = identifyingNode) {
            value type = term.typeModel;
            
            if (!ModelUtil.isTypeUnknown(type)) {
                if (!unplural, type.classOrInterface || type.typeParameter) {
                    addNameProposals(names, false, type.declaration.name);
                }
            }
            value unit = myNode.unit;
            if (unit.isIterableType(type)) {
                Type? iter = unit.getIteratedType(type);
                
                if (exists iter, iter.classOrInterface || iter.typeParameter) {
                    addNameProposals(names, !unplural, iter.declaration.name);
                }
            }
        }
        
        if (names.empty) {
            names.add("it");
        }

        return names.sequence();
    }
    
    shared void addNameProposals(MutableSet<String> names, Boolean plural, String tn) {
        value name = (tn.first?.lowercased?.string else "") + tn.spanFrom(1);
        value matcher = idPattern.matcher(javaString(name));
        
        while (matcher.find()) {
            value loc = matcher.start(2);
            value initial = name.span(matcher.start(1), loc - 1).lowercased;
            value subname = initial + name.spanFrom(loc + 1) + (if (plural) then "s" else "");

            if (keywords.contains(subname)) {
                names.add("\\i" + subname);
            } else {
                names.add(subname);
            }
        }
    }
}