defmodule AuthorizeNet.BaseCustomer do
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
  defstruct id: nil,
    email: nil,
    description: nil

  @type t :: %AuthorizeNet.BaseCustomer{}

  @spec new( String.t, String.t, String.t
  ) :: AuthorizeNet.BaseCustomer.t | no_return
  def new( id, description, email) do
    %AuthorizeNet.BaseCustomer{
      id: id,
      description: description,
      email: email
    }
  end

  def to_xml(customer) do
    [
      merchantCustomerId: customer.id,
      description: customer.description,
      email: customer.email,
    ]
  end
end
