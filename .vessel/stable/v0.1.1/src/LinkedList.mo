import Array "mo:base-0.7.3/Array";

module {
    public type LinkedList<V> = ?(V, LinkedList<V>);

    public func size<V>(l : LinkedList<V>) : Nat {
        size_(l, 0);
    };

    private func size_<V>(l : LinkedList<V>, acc : Nat) : Nat {
        switch (l) {
            case (null)     { acc;              };
            case (?(_, l)) { size_(l, acc + 1); };
        };
    };

    public func fromArray<V>(xs : [V]) : LinkedList<V> {
        Array.foldRight(
            xs, null,
            func (
                x : V,
                ys : LinkedList<V>,
            ) : LinkedList<V> {
                ?(x, ys);
            },
        );
    };
};
