signature Alias where {
class (Alias.Alias :: * -> * -> *) a b | a -> b, b -> a where {
};
 
instance Alias Alias.Alias a a;
			      
class (Alias.NumAlias :: # -> # -> *) a b | a -> b, b -> a where {
};
 
instance Alias Alias.NumAlias a a
}
