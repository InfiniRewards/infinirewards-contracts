use cainome::rs::Abigen;
use std::collections::HashMap;

fn main() {
    // Aliases added from the ABI
    let mut aliases = HashMap::new();
    aliases.insert(
        String::from("openzeppelin_security::pausable::PausableComponent::Event"),
        String::from("PausableComponentEvent"),
    );
    aliases.insert(
        String::from("openzeppelin_access::ownable::ownable::OwnableComponent::Event"),
        String::from("OwnableComponentEvent"),
    );
    aliases.insert(
        String::from("openzeppelin_upgrades::upgradeable::UpgradeableComponent::Event"),
        String::from("UpgradeableComponentEvent"),
    );

    let factory_abigen =
        Abigen::new("factory", "./abi/factory_contract.abi.json").with_types_aliases(aliases).with_derives(vec!["serde::Serialize".to_string(), "serde::Deserialize".to_string()]);

        factory_abigen
            .generate()
            .expect("Fail to generate bindings")
            .write_to_file("./src/abi/factory_contract.rs")
            .unwrap();
}