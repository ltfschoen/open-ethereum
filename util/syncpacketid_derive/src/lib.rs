// Copyright 2015-2019 Parity Technologies (UK) Ltd.
// This file is part of Parity Ethereum.

// Parity Ethereum is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Parity Ethereum is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Parity Ethereum.  If not, see <http://www.gnu.org/licenses/>.

#![recursion_limit="128"]

// Needs to be "extern crate" even in rust 2018:
// https://blog.rust-lang.org/2018/12/21/Procedural-Macros-in-Rust-2018.html
extern crate proc_macro;

use proc_macro2::Ident;
use quote::quote;
use syn::{Data, DeriveInput, Meta, MetaList, NestedMeta};

fn parse_protocol_arguments(args: MetaList) -> Ident {
	if args.nested.len() != 1 {
		panic!("protocol attribute should have exactly one argument");
	}

	match args.nested.first().expect("protocol attribute without value").value() {
		// Meta argument
		NestedMeta::Meta(meta) => match meta {
			Meta::Word(ident) => ident.clone(),
			_ => panic!("nested arguments to protocol are not allowed"),
		},
		// Quoted string
		_ => panic!("protocol argument must be an unquoted identifier")
	}
}

/// Helper function to parse arguments to the protocol attribute.
/// Syntax should be #[protocol(P)] PacketName = 0xNN,
fn parse_protocol_attribute(input: Meta) -> Ident {
	// Arguments to invocation attributes are delivered as a list
	match input {
		Meta::Word(_) => panic!("protocol attribute without argument"),
		Meta::List(args) => parse_protocol_arguments(args),
		_ => panic!("unsupported syntax")
	}
}

/// The SyncPackets derive-macro will provide an enum with this attribute:
///
/// * With a method "from_u8" which will optionally convert a u8 value to
///   one of the variants or None if the value is unknown.
///
/// * With an implementation of a trait PacketInfo to get the packet id and
///   the protocol from instances of the enum.
#[proc_macro_derive(SyncPackets, attributes(protocol))]
pub fn sync_packets(input: proc_macro::TokenStream) -> proc_macro::TokenStream {
	let ast = syn::parse(input).expect("invalid enum syntax");
	let gen = impl_sync_packets(&ast);
	gen.into()
}

fn impl_sync_packets(ast: &DeriveInput) -> proc_macro2::TokenStream {
	let body = match ast.data {
		Data::Enum(ref e) => e,
		_ => panic!("#[derive(SyncPackets)] is only defined for enums."),
	};

	let enum_name = &ast.ident;

	if body.variants.is_empty() {
		panic!("enum {} has no variants defined", enum_name);
	}

	// Apparently quote! consumes interpolated variables. Clone ids
	// to use them twice.
	let idents_from_u8: Vec<_> = body.variants.iter().map(|v| &v.ident).collect();
	let idents_enum = idents_from_u8.clone();

	// Within each variant of the enum find the first "protocol" attribute
	// and extract its argument
	let protocols:Vec<_> = body.variants.iter()
		.filter_map(
			|v| v.attrs
				.iter()
				.find(|&x| x.path.is_ident("protocol"))
				.or_else(|| panic!("enum variant without protocol attribute in {}", &enum_name))
		).map(|a| parse_protocol_attribute(a
										   .parse_meta()
										   .clone()
										   .expect("unknown arguments passed to protocol"))
		).collect();


	// Values asigned to the variants in the enum
	let values: Vec<_> = body.variants.iter()
		.map(
			|v| v.discriminant
				.clone()
				.expect("enum pattern is not discriminant; should have assigned a unique value such as Foo = 1")
				.1
		)
		.collect();

	quote!{
		use network::{PacketId, ProtocolId};

		impl #enum_name {
			pub fn from_u8(id: u8) -> Option<SyncPacket> {
				match id {
					#(#values => Some(#idents_from_u8)),*,
					_ => None

				}
			}
		}

		use self::SyncPacket::*;

		/// Provide both subprotocol and packet id information within the
		/// same object.
		pub trait PacketInfo {
			fn id(&self) -> PacketId;
			fn protocol(&self) -> ProtocolId;
		}

		impl PacketInfo for #enum_name {
			fn protocol(&self) -> ProtocolId {
				match self {
					#(#idents_enum => #protocols),*
				}
			}

			fn id(&self) -> PacketId {
				(*self) as PacketId
			}
		}
	}
}