import Array "mo:base-0.7.3/Array";
import Hash "mo:base-0.7.3/Hash";
import Iter "mo:base-0.7.3/Iter";
import Nat32 "mo:base-0.7.3/Nat32";

import AL "AssociationList";

module {
    // Based on "mo:base-0.7.3/HashMap".

    public type HashMap<K, V> = {
        var table : [var AL.AssociationList<K, V>];
        var size  : Nat;
    };

    public func empty<K, V>() : HashMap<K, V> {
        return {
            var table = [var];
            var size  = 0;
        };
    };

    /// Returns the number of entries in the HashMap.
    public func size<K, V>(
        m : HashMap<K, V>,
    ) : Nat {
        m.size;
    };

    /// Removes the entry with the key 'k' and returns the removed value and the new HashMap.
    public func remove<K, V>(
        m     : HashMap<K, V>,
        k     : K, 
        hash  : (K) -> Hash.Hash,
        equal : (K, K) -> Bool,
    ) : (HashMap<K, V>, ?V) {
        let s = m.table.size();
        if (s == 0) return (m, null);

        let n = Nat32.toNat(hash(k)) % s;
        let (kv, ov) = AL.delete<K, V>(
            m.table[n], k, equal,
        );
        m.table[n] := kv;
        switch(ov){
            case (null) {}; // Nothing was removed.
            case (? _)  { m.size -= 1; };
        };
        (m, ov);
    };

    /// Gets the entry with the key 'k' and returns its associated value.
    public func get<K, V>(
        m     : HashMap<K, V>,
        k     : K,
        hash  : (K) -> Hash.Hash,
        equal : (K, K) -> Bool,
    ) : ?V {
        let s = m.table.size();
        if (0 == s) return null;

        AL.get<K, V>(m.table[Nat32.toNat(hash(k)) % s], k, equal);
    };

    /// Inserts the value 'v' at key 'k' and returns the previous value stored at 'k'.
    public func insert<K, V>(
        m     : HashMap<K, V>,
        k     : K,
        hash  : (K) -> Hash.Hash,
        equal : (K, K) -> Bool,
        v     : V,
    ) : (HashMap<K, V>, ?V) {
        let s = m.table.size();

        // Recalculate all tables.
        if (s <= m.size) {
            // Double the table size.
            let size = if (m.size == 0) { 1; } else { s * 2; };
            let table_ = Array.init<AL.AssociationList<K, V>>(size, null);
            for (i in m.table.keys()) {
                var kvs = m.table[i];
                label l loop {
                    switch (kvs) {
                        case (null) { break l; };
                        case (? ((k, v), ks)) {
                            let n = Nat32.toNat(hash(k)) % table_.size();
                            table_[n] := ?((k, v), table_[n]);
                            kvs := ks;
                        };
                    };
                };
            };
            m.table := table_;
        };

        let n = Nat32.toNat(hash(k)) % m.table.size();
        let (kv, ov) = AL.insert<K, V>(
            m.table[n], k, equal, v,
        );
        m.table[n] := kv;
        switch(ov){
            case (null) {  m.size += 1; };
            case (? _)  {}; // Value was replaced.
        };
        (m, ov);
    };

    public func entries<K, V>(
        m : HashMap<K, V>,
    ) : Iter.Iter<(K, V)> {
        var table = m.table;
        if (table.size() == 0) return object {
            public func next() : ?(K, V) { null };
        };
        object {
            var kvs = table[0];
            var i   = 1;
            public func next() : ?(K, V) {
                switch (kvs) {
                    case (? (kv, ks)) {
                        kvs := ks;
                        ?kv;
                    };
                    case (null) {
                        if (table.size() <= i) return null;
                        kvs := table[i]; i += 1;
                        next();
                    };
                };
            };
        };
    };
};
