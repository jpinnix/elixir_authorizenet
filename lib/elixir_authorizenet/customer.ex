defmodule AuthorizeNet.Customer do
  @moduledoc """
  Handles customer profiles (http://developer.authorize.net/api/reference/index.html#manage-customer-profiles).

  Copyright 2015 Marcelo Gornstein <marcelog@gmail.com>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  """
  use AuthorizeNet.Helper.XML
  alias AuthorizeNet, as: Main
  alias AuthorizeNet.PaymentProfile, as: PaymentProfile
  alias AuthorizeNet.Address, as: Address
  defstruct description: nil,
    email: nil,
    id: nil,
    profile_id: nil,
    payment_profiles: [],
    shipping_addresses: []

  @type t :: %AuthorizeNet.Customer{}

  @doc """
  Deletes a shipping address. See:
  http://developer.authorize.net/api/reference/index.html#manage-customer-profiles-delete-customer-shipping-address
  """
  @spec delete_shipping_address(Integer, Integer) :: :ok | no_return
  def delete_shipping_address(customer_id, address_id) do
    Main.req :deleteCustomerShippingAddressRequest, [
      customerProfileId: customer_id,
      customerAddressId: address_id
    ]
    :ok
  end

  @doc """
  Updates a shipping address. See:
  http://developer.authorize.net/api/reference/index.html#manage-customer-profiles-update-customer-shipping-address
  """
  @spec update_shipping_address(Address.t) :: AuthorizeNet.Address.t | no_return
  def update_shipping_address(address) do
    Main.req :updateCustomerShippingAddressRequest, [
      customerProfileId: address.customer_id,
      address: Address.to_xml(address)
    ]
   address
  end

  @doc """
  Creates a shipping address for the customer. See:
  http://developer.authorize.net/api/reference/index.html#manage-customer-profiles-create-customer-shipping-address
  """
  @spec create_shipping_address(Integer, Address.t) :: Address.t | no_return
  def create_shipping_address(customer_id, address) do
    doc = Main.req :createCustomerShippingAddressRequest, [
      customerProfileId: customer_id,
      address: Address.to_xml(address)
    ]
   address_id = xml_one_value_int doc, "//customerAddressId"
   %AuthorizeNet.Address{address | id: address_id, customer_id: customer_id}
  end

  @doc """
  Returns a shipping address. See:
  http://developer.authorize.net/api/reference/index.html#manage-customer-profiles-get-customer-shipping-address
  """
  @spec get_shipping_address(Integer, Integer) :: Address.t | no_return
  def get_shipping_address(customer_id, address_id) do
    doc = Main.req :getCustomerShippingAddressRequest, [
      customerProfileId: customer_id,
      customerAddressId: address_id
    ]
    Address.from_xml doc, customer_id
  end

  @doc """
  Returns a customer profile by customer profile ID. See:
  http://developer.authorize.net/api/reference/index.html#manage-customer-profiles-get-customer-profile
  """
  @spec get(Integer):: AuthorizeNet.Customer.t | no_return
  def get(profile_id) do
    doc = Main.req :getCustomerProfileRequest, [customerProfileId: profile_id]
    from_xml doc
  end

  @doc """
  Returns all customer profile IDs known by Authorize.Net. See:
  http://developer.authorize.net/api/reference/index.html#manage-customer-profiles-get-customer-profile-ids
  """
  @spec get_all():: [Integer] | no_return
  def get_all() do
    doc = Main.req :getCustomerProfileIdsRequest, []
    for profile_id <- xml_value doc, "//numericString"  do
      {profile_id, ""} = Integer.parse profile_id
      profile_id
    end
  end

  @doc """
  Updates a customer profile given a valid customer profile ID. See:
  http://developer.authorize.net/api/reference/index.html#manage-customer-profiles-update-customer-profile
  """
  @spec update(
    Integer, String.t, String.t, String.t
  ) :: AuthorizeNet.Customer.t | no_return
  def update(profile_id, id, description, email) do
    profile = [
      merchantCustomerId: id,
      description: description,
      email: email,
      customerProfileId: profile_id
    ]
    Main.req :updateCustomerProfileRequest, [profile: profile]
    new id, profile_id, description, email
  end

  @doc """
  Creates a customer profile. See:
  http://developer.authorize.net/api/reference/index.html#manage-customer-profiles-create-customer-profile
  """
  @spec create(
    String.t, String.t, String.t
  ) :: AuthorizeNet.Customer.t | no_return
  def create(id, description, email) do
    profile = new id, nil, description, email
    profile_xml = to_xml profile
    doc = Main.req :createCustomerProfileRequest, [
      profile: profile_xml,
      validationMode: "none"
    ]
   profile_id = xml_one_value_int doc, "//customerProfileId"
   %AuthorizeNet.Customer{profile | profile_id: profile_id}
  end

  @spec create_from_transaction(
    String.t, String.t, String.t, String.t
  ) :: AuthorizeNet.Customer.t | no_return
  def create_from_transaction(id, transaction_id, description, email) do
    profile = new id, nil, description, email
    profile_xml = to_xml profile
    doc = Main.req :createCustomerProfileFromTransactionRequest, [
      customer: profile_xml,
      transId: transaction_id,
    ]
   profile_id = xml_one_value_int doc, "//customerProfileId"
   %AuthorizeNet.Customer{profile | profile_id: profile_id}
  end

  @doc """
  Deletes a customer profile by customer profile ID. See:
  http://developer.authorize.net/api/reference/index.html#manage-customer-profiles-delete-customer-profile
  """
  @spec delete(Integer) :: :ok | no_return
  def delete(customer_id) do
    Main.req :deleteCustomerProfileRequest, [
      customerProfileId: to_string(customer_id)
    ]
    :ok
  end

  @spec new(
    String.t, Integer, String.t, String.t, [PaymentProfile.t], [Address.t]
  ) :: AuthorizeNet.Customer.t | no_return
  defp new(
    id, profile_id, description, email,
    payment_profiles \\ [], shipping_addresses \\ []
  ) do
    %AuthorizeNet.Customer{
      id: id,
      description: description,
      email: email,
      profile_id: profile_id,
      payment_profiles: payment_profiles,
      shipping_addresses: shipping_addresses
    }
  end

  defp to_xml(customer) do
    [
      merchantCustomerId: customer.id,
      description: customer.description,
      email: customer.email,
      customerProfileId: customer.profile_id
    ]
  end

  @doc """
  Builds an Customer from an xmlElement record.
  """
  @spec from_xml(Record) :: AuthorizeNet.Customer.t
  def from_xml(doc) do
    profile_id = xml_one_value_int doc, "//customerProfileId"
    payment_profiles = for p <- xml_find(doc, ~x"//paymentProfiles"l) do
      PaymentProfile.from_xml p, profile_id
    end
    shipping_addresses = for a <- xml_find(doc, ~x"//shipToList"l) do
      Address.from_xml a, profile_id
    end
    new(
      xml_one_value(doc, "//merchantCustomerId"),
      profile_id,
      xml_one_value(doc, "//description"),
      xml_one_value(doc, "//email"),
      payment_profiles,
      shipping_addresses
    )
  end
end
