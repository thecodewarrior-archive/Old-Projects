pub type TestAtom = ::string_cache::Atom<TestAtomStaticSet>;
pub struct TestAtomStaticSet;
impl ::string_cache::StaticAtomSet for TestAtomStaticSet {
    fn get() -> &'static ::string_cache::PhfStrSet {
        static SET: ::string_cache::PhfStrSet = ::string_cache::PhfStrSet {
            key: 8795782494440154893,
            disps: &[(6, 8), (0, 0), (0, 6)],
            atoms: &[
    "body",
    "font-weight",
    "area",
    "html",
    "a",
    "",
    "br",
    "address",
    "head",
    "b",
    "id"
],
        };
        &SET
    }
    fn empty_string_index() -> u32 {
        5
    }
}
#[macro_export]
macro_rules! test_atom {
("body") => { $crate::atom::tests::TestAtom { unsafe_data: 0x2, phantom: ::std::marker::PhantomData } };
("font-weight") => { $crate::atom::tests::TestAtom { unsafe_data: 0x100000002, phantom: ::std::marker::PhantomData } };
("area") => { $crate::atom::tests::TestAtom { unsafe_data: 0x200000002, phantom: ::std::marker::PhantomData } };
("html") => { $crate::atom::tests::TestAtom { unsafe_data: 0x300000002, phantom: ::std::marker::PhantomData } };
("a") => { $crate::atom::tests::TestAtom { unsafe_data: 0x400000002, phantom: ::std::marker::PhantomData } };
("") => { $crate::atom::tests::TestAtom { unsafe_data: 0x500000002, phantom: ::std::marker::PhantomData } };
("br") => { $crate::atom::tests::TestAtom { unsafe_data: 0x600000002, phantom: ::std::marker::PhantomData } };
("address") => { $crate::atom::tests::TestAtom { unsafe_data: 0x700000002, phantom: ::std::marker::PhantomData } };
("head") => { $crate::atom::tests::TestAtom { unsafe_data: 0x800000002, phantom: ::std::marker::PhantomData } };
("b") => { $crate::atom::tests::TestAtom { unsafe_data: 0x900000002, phantom: ::std::marker::PhantomData } };
("id") => { $crate::atom::tests::TestAtom { unsafe_data: 0xa00000002, phantom: ::std::marker::PhantomData } };
}
