import com.redhat.ceylon.ide.common.platform {
    CommonDocument
}
import com.redhat.ceylon.compiler.typechecker.tree {
    Tree,
    Node,
    Visitor
}
import ceylon.collection {
    TreeMap
}


shared <Integer->Node>? getFirstValidLocation(Tree.CompilationUnit rootNode,
    CommonDocument document, Integer requestedLine) {

    value nodes = TreeMap<Integer, Node>(uncurry(Integer.compare));
    
    object extends Visitor() {
        void check(Node node) {
            if (exists startIndex = node.startIndex?.intValue(),
                exists stopIndex = node.endIndex?.intValue()) {

                Integer nodeStartLine = document.getLineOfOffset(startIndex);

                if (nodeStartLine >= requestedLine) {
                    nodes.put(nodeStartLine, node);
                } else {
                    value nodeEndLine = document.getLineOfOffset(stopIndex);
                    if (nodeEndLine >= requestedLine) {
                        nodes.put(requestedLine, node);
                    }
                }
            }
        }
        
        shared actual void visit(Tree.Annotation that) {
        }
        
        shared actual void visit(Tree.ExecutableStatement that) {
            check(that);
            super.visit(that);
        }
        
        shared actual void visit(Tree.SpecifierOrInitializerExpression that) {
            check(that);
            super.visit(that);
        }
        
        shared actual void visit(Tree.Expression that) {
            check(that);
            super.visit(that);
        }
    }.visit(rootNode);
    
    return nodes.first;
}
