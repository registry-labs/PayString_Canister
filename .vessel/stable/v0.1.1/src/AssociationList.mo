
import LL "LinkedList";

module {
    public type AssociationList<K, V> = LL.LinkedList<(K, V)>;

    public func delete<K, V>(
        l     : AssociationList<K, V>,
        k     : K,
        equal : (K, K) -> Bool,
    ) : (AssociationList<K, V>, ?V) {
        switch (l) {
            case (null) { (null, null); };
            case (? ((k_, v), ls)) {
                if (equal(k, k_)) return (ls, ?v);
                let (l_, ov) = delete(ls, k, equal);
                (?((k_, v), l_), ov);
            };
        };
    };

    public func get<K, V>(
        l     : AssociationList<K, V>,
        k     : K,
        equal : (K, K) -> Bool,
    ) : ?V {
        switch (l) {
            case (null) { null; };
            case (? ((k_, v), ls)) {
                if (equal(k, k_)) return ?v;
                get(ls, k, equal);
            };
        };
    };

    public func insert<K, V>(
        l     : AssociationList<K, V>,
        k     : K,
        equal : (K, K) -> Bool,
        v     : V,
    ) : (AssociationList<K, V>, ?V) {
        switch (l) {
            case (null) { (?((k, v), null), null); };
            case (? ((k_, v_), ls)) {
                if (equal(k, k_)) return (?((k, v), ls), ?v_);
                let (l_, ov) = insert(ls, k, equal, v);
                (?((k_, v_), l_), ov);
            };
        };
    };
};
