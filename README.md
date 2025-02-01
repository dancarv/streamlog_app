# streamlog_app


Para inicio do projeto, vamos dividir em três partes principais: **usuários**, **funcionalidades** e **fluxo básico**.

### 🚀 **1. Tipos de Usuários**
- **Cliente:** Faz pedidos de coleta, acompanha o status e rastreia a entrega.  
- **Entregador:** Visualiza as coletas disponíveis na rota, aceita coletas e atualiza o status da coleta.  
- **Administrador (opcional):** Gerencia usuários, coletas e estatísticas.

---

### 📋 **2. Funcionalidades Principais**

#### **Para o Cliente:**
- Cadastro/Login (com e-mail e senha ou Google/Facebook).
- Realizar pedidos (informa material a ser coletado, definir endereço de coleta e entrega).
- Acompanhar status da coleta em tempo real.
- Histórico das coletas.

#### **Para o Entregador:**
- Cadastro/Login.
- Visualizar coletas disponíveis.
- Aceitar coleta na rota e atualizar status (em andamento, concluído).
- Navegação com integração a mapas para rastreamento da entrega.

#### **Para o Administrador (se necessário):**
- Dashboard com estatísticas de pedidos.
- Gerenciamento de usuários e entregadores.
- Configuração de categorias e produtos (se for um marketplace).

---

### 🔄 **3. Fluxo Básico do App**

1. **Autenticação:** O usuário faz login ou cadastro.  
2. **Tela Inicial:** Cliente vê coletas, entregador vê coletas disponíveis.  
3. **Pedido:** Cliente faz o pedido de coleta → pedido vai para o backend → entregador aceita o pedido de coleta.  
4. **Rastreamento:** Cliente acompanha a coleta em tempo real.  
5. **Finalização:** Pedido concluído → atualização de status → feedback do cliente.

OBS:
- A **temperatura inicial** de um item só pode ser registrada quando o status da coleta for "em coleta".  
- A **temperatura final** só pode ser registrada quando o status da coleta for "entregue".  


---

### 🗂️ **4. Tecnologias de Suporte**

- **Backend:** APIs REST com Spring Boot, banco de dados relacional (MySQL/PostgreSQL), autenticação JWT.  
- **Frontend:** Flutter com gerenciamento de estado (Provider ou Riverpod).  
- **Mapas:** API do Google Maps para rastreamento de entregas.  
- **Notificações Push:** Para alertar sobre atualizações de pedidos.

Ótimo! Vamos começar pela **modelagem do banco de dados**, depois seguimos para a definição das APIs REST.

---

### 🗂️ **1. Modelagem do Banco de Dados**

Pensando nos fluxos do app, precisaremos das seguintes tabelas principais:

1. **Usuário (`users`)**  
   - `id` (PK)  
   - `nome`, `email`, `senha`, `telefone`, `tipo` (cliente, coletor, admin)  

2. **Endereço (`addresses`)**  
   - `id` (PK)  
   - `user_id` (FK para `users`)  
   - `rua`, `cidade`, `estado`, `cep`, `latitude`, `longitude`  

3. **Coleta (`collections`)**  
   - `id` (PK)  
   - `cliente_id` (FK para `users`)  
   - `coletor_id` (FK para `users`, pode ser `null` até ser atribuído)  
   - `endereco_coleta_id` (FK para `addresses`)  
   - `endereco_entrega_id` (FK para `addresses`)  
   - `status` (pendente, em coleta, em transporte, entregue, cancelada)  
   - `data_criacao`, `data_entrega`  

4. **Itens da Coleta (`collection_items`)**  
   - `id` (PK)  
   - `collection_id` (FK para `collections`)  
   - `descricao_material`  
   - `quantidade`  
   - `observacoes` (ex: condições especiais de transporte)  
   - `initial_temperature` (float) → Temperatura do material no momento da coleta  
   - `end_temperature` (float) → Temperatura do material no momento da entrega  

5. **Histórico de Status (`collection_status_history`)**  
   - `id` (PK)  
   - `collection_id` (FK para `collections`)  
   - `status`  
   - `data_alteracao`  

---

### 🚀 **2. Definição das APIs REST (Atualizada)**

#### **Autenticação**  
- `POST /auth/register` → Cadastro de usuário  
- `POST /auth/login` → Login com token JWT  

#### **Usuários**  
- `GET /users/{id}` → Detalhes do usuário  
- `PUT /users/{id}` → Atualizar perfil  

#### **Coletas**  
- `POST /collections` → Criar nova coleta  
- `GET /collections` → Listar coletas do usuário  
- `GET /collections/{id}` → Detalhes de uma coleta  
- `PUT /collections/{id}/status` → Atualizar status da coleta (coletor/admin)  
- `POST /collections/{id}/assign` → Atribuir coleta a um coletor  

#### **Itens da Coleta (Controle de Temperatura)**  
- `PUT /collection-items/{id}/temperature/initial` → Registrar temperatura inicial (momento da coleta)  
- `PUT /collection-items/{id}/temperature/end` → Registrar temperatura final (momento da entrega)  

#### **Coletor**  
- `GET /collections/available` → Listar coletas disponíveis  
- `PUT /collections/{id}/accept` → Aceitar uma coleta  
- `PUT /collections/{id}/update-location` → Atualizar localização em tempo real  

---

### 🔐 **3. Segurança (JWT)**

Cada requisição protegida (como criação de pedidos, atualização de status) exigirá um **token JWT** no header:
```http
Authorization: Bearer <token>
```

# DDL

```sql
-- Script SQL para importação no ERwin

CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),
    tipo VARCHAR(50)
);

CREATE TABLE addresses (
    id INT PRIMARY KEY,
    user_id INT,
    rua VARCHAR(255),
    cidade VARCHAR(100),
    estado VARCHAR(50),
    cep VARCHAR(20),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    CONSTRAINT fk_user_address FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE collections (
    id INT PRIMARY KEY,
    cliente_id INT,
    coletor_id INT,
    endereco_coleta_id INT,
    endereco_entrega_id INT,
    status VARCHAR(50),
    data_criacao TIMESTAMP,
    data_entrega TIMESTAMP,
    CONSTRAINT fk_cliente FOREIGN KEY (cliente_id) REFERENCES users(id),
    CONSTRAINT fk_coletor FOREIGN KEY (coletor_id) REFERENCES users(id),
    CONSTRAINT fk_endereco_coleta FOREIGN KEY (endereco_coleta_id) REFERENCES addresses(id),
    CONSTRAINT fk_endereco_entrega FOREIGN KEY (endereco_entrega_id) REFERENCES addresses(id)
);

CREATE TABLE collection_items (
    id INT PRIMARY KEY,
    collection_id INT,
    descricao_material VARCHAR(255),
    quantidade INT,
    observacoes TEXT,
    initial_temperature FLOAT,
    end_temperature FLOAT,
    CONSTRAINT fk_collection_item FOREIGN KEY (collection_id) REFERENCES collections(id)
);

CREATE TABLE collection_status_history (
    id INT PRIMARY KEY,
    collection_id INT,
    status VARCHAR(50),
    data_alteracao TIMESTAMP,
    CONSTRAINT fk_collection_status FOREIGN KEY (collection_id) REFERENCES collections(id)
);

```

## **APIs para o App de Entrega**

### **1. Endpoints de Usuário**

**Cadastro de Usuário**  
- **POST** `/api/users/register`  
- **Body:**  
```json
{
  "name": "João Silva",
  "email": "joao@email.com",
  "senha": "senhaSegura123",
  "telefone": "11999998888",
  "tipo": "cliente" // ou "coletor"
}
```
- **Resposta:** `201 Created`

**Login de Usuário**  
- **POST** `/api/users/login`  
- **Body:**  
```json
{
  "email": "joao@email.com",
  "senha": "senhaSegura123"
}
```
- **Resposta:** `200 OK` com token JWT

**Atualizar Perfil**  
- **PUT** `/api/users/{id}`  
- **Headers:** `Authorization: Bearer <token>`  
- **Body:**  
```json
{
  "name": "João da Silva",
  "telefone": "11999997777"
}
```
- **Resposta:** `200 OK`

---

### **2. Endpoints de Coleta**

**Criar Coleta**  
- **POST** `/api/collections`  
- **Headers:** `Authorization: Bearer <token>`  
- **Body:**  
```json
{
  "cliente_id": 1,
  "coletor_id": 2,
  "endereco_coleta_id": 5,
  "endereco_entrega_id": 6,
  "status": "pendente"
}
```
- **Resposta:** `201 Created`

**Atualizar Status da Coleta**  
- **PATCH** `/api/collections/{id}/status`  
- **Headers:** `Authorization: Bearer <token>`  
- **Body:**  
```json
{
  "status": "em_andamento"
}
```
- **Resposta:** `200 OK`

**Listar Coletas do Usuário**  
- **GET** `/api/collections?userId=1`  
- **Headers:** `Authorization: Bearer <token>`  
- **Resposta:** `200 OK`

---

### **3. Endpoints de Itens da Coleta**

**Adicionar Item à Coleta**  
- **POST** `/api/collections/{collectionId}/items`  
- **Headers:** `Authorization: Bearer <token>`  
- **Body:**  
```json
{
  "descricao_material": "Produto Químico",
  "quantidade": 3,
  "observacoes": "Manter em temperatura ambiente",
  "initial_temperature": 22.5
}
```
- **Resposta:** `201 Created`

**Registrar Temperatura de Entrega**  
- **PATCH** `/api/collection-items/{itemId}/temperature`  
- **Headers:** `Authorization: Bearer <token>`  
- **Body:**  
```json
{
  "end_temperature": 24.0
}
```
- **Resposta:** `200 OK`

**Listar Itens da Coleta**  
- **GET** `/api/collections/{collectionId}/items`  
- **Headers:** `Authorization: Bearer <token>`  
- **Resposta:** `200 OK`

---

