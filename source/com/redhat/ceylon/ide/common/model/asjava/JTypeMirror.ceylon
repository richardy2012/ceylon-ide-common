import ceylon.interop.java {
    javaClass
}

import com.redhat.ceylon.model.loader.impl.reflect.mirror {
    ReflectionType
}
import com.redhat.ceylon.model.loader.mirror {
    TypeMirror,
    TypeKind,
    ClassMirror
}
import com.redhat.ceylon.model.typechecker.model {
    Type,
    ClassOrInterface
}

import java.lang {
    JString=String,
    Class
}
import java.util {
    List,
    Collections,
    ArrayList
}

TypeMirror longMirror = PrimitiveMirror(TypeKind.long, "long");

TypeMirror doubleMirror = PrimitiveMirror(TypeKind.double, "double");

TypeMirror booleanMirror = PrimitiveMirror(TypeKind.boolean, "boolean");

TypeMirror intMirror = PrimitiveMirror(TypeKind.int, "int");

TypeMirror byteMirror = PrimitiveMirror(TypeKind.byte, "byte");

TypeMirror stringMirror = JavaClassType(javaClass<JString>());

TypeMirror objectMirror = JavaClassType(javaClass<Object>());

class JTypeMirror(Type type) satisfies TypeMirror {
    
    componentType => null;
    
    shared actual ClassMirror? declaredClass {
        if (type.classOrInterface) {
            assert(is ClassOrInterface decl = type.declaration);
            
            return JClassMirror(decl);
        }
        
        return null;
    }
    
    kind => TypeKind.declared;
    
    lowerBound => null;
    
    primitive => false;
    
    qualifiedName => type.asQualifiedString();
    
    qualifyingType => null;
    
    raw => type.raw;
    
    shared actual List<TypeMirror> typeArguments {
        value args = ArrayList<TypeMirror>();
        
        for (arg in type.typeArgumentList) {
            args.add(JTypeMirror(arg));
        }
        
        return args;
    }
    
    typeParameter => null;
    
    upperBound => null;
    
    string => type.asString();
}

class PrimitiveMirror(TypeKind _kind, String name) satisfies TypeMirror {
    componentType => null;
    
    declaredClass => null;
    
    kind => _kind;
    
    lowerBound => null;
    
    primitive => true;
    
    qualifiedName => name;
    
    qualifyingType => null;
    
    raw => false;
    
    typeArguments
            => Collections.emptyList<TypeMirror>();
    
    typeParameter => null;
    
    upperBound => null;
    
    string => name;
}

class JavaClassType<Type>(Class<Type> type) extends ReflectionType(type)
        given Type satisfies Object {
    string => type.simpleName;
}