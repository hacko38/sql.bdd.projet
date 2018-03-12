/*------------------------------------------------------------
*        Script SQLSERVER 
------------------------------------------------------------*/
use Pistons
go

/*------------------------------------------------------------
-- Creation des TYPES
------------------------------------------------------------*/
CREATE TYPE TypeDiametre
FROM float
NULL

CREATE TYPE TypeCategorie
FROM VARCHAR(5)
NOT NULL

CREATE TYPE TypeModele
FROM VARCHAR(5)
NOT NULL

CREATE TYPE TypePieceLot
FROM INT
NOT NULL
go

/*------------------------------------------------------------
-- Table: MODELE
------------------------------------------------------------*/
CREATE TABLE MODELE(
	Modele   TypeModele PRIMARY KEY,
	Diametre TypeDiametre,
	Supprimée bit   
);

/*------------------------------------------------------------
-- Table: MACHINE
------------------------------------------------------------*/
CREATE TABLE MACHINE(
	Num_Presse  smallint  NOT NULL	PRIMARY KEY		CHECK (Num_Presse LIKE '[0-9][0-9][0-9][0-9]'),
	Etat_Presse bit,
	Supprimée bit   
);


/*------------------------------------------------------------
-- Table: CATEGORIE
------------------------------------------------------------*/
CREATE TABLE CATEGORIE(
	Categorie      TypeCategorie  PRIMARY KEY,
	Tolerance_Mini TypeDiametre   ,
	Tolerance_Maxi TypeDiametre   
);
go

/*------------------------------------------------------------
-- Table: ETAT_LOT
------------------------------------------------------------*/
CREATE TABLE ETAT_LOT(
	Code_Etat tinyint  NOT NULL PRIMARY KEY,
	Nom_Etat  VARCHAR (10)  
);
go

/*------------------------------------------------------------
-- Table: LOT
------------------------------------------------------------*/
CREATE TABLE LOT(
	Id_Lot              TypePieceLot		PRIMARY KEY		IDENTITY (1,1) ,
	Nb_Pieces_demandees INT   ,
	Date_Fabrication    DATETIME  ,
	Num_Presse          smallint   REFERENCES MACHINE(Num_Presse),
	Modele              TypeModele  REFERENCES MODELE(Modele),
	Code_Etat           tinyint  REFERENCES ETAT_LOT(Code_Etat),
	Moyenne_HL          TypeDiametre   ,
	Moyenne_HT          TypeDiametre   ,
	Moyenne_BT          TypeDiametre   ,
	Moyenne_BL          TypeDiametre   ,
	Maximum_HL          TypeDiametre   ,
	Maximum_HT          TypeDiametre   ,
	Maximum_BL          TypeDiametre   ,
	Maximum_BT          TypeDiametre   ,
	Minimum_HT          TypeDiametre   ,
	Minimum_HL          TypeDiametre   ,
	Minimum_BL          TypeDiametre   ,
	Minimum_BT          TypeDiametre   ,
	Ecart_Type_HL       TypeDiametre   ,
	Ecart_Type_HT       TypeDiametre   ,
	Ecart_Type_BT       TypeDiametre   ,
	Ecart_Type_BL       TypeDiametre 

);



/*------------------------------------------------------------
-- Table: STOCK
------------------------------------------------------------*/
CREATE TABLE STOCK(
	Modele         TypeModele  REFERENCES MODELE(Modele),
	Categorie      TypeCategorie  REFERENCES CATEGORIE(Categorie),
	PRIMARY KEY (Modele, Categorie),
	Quantite_Stock INT   ,
	Seuil_Mini     INT ,
	DateDerniereCommande VARCHAR(50)  
);
go


/*------------------------------------------------------------
-- Table: PIECE
------------------------------------------------------------*/
CREATE TABLE PIECE(
	Id_Piece    TypePieceLot		PRIMARY KEY		IDENTITY (1,1) ,
	Diametre_HL TypeDiametre   ,
	Diametre_HT TypeDiametre   ,
	Diametre_BL TypeDiametre   ,
	Diametre_BT TypeDiametre   ,
	Categorie   TypeCategorie  REFERENCES CATEGORIE(Categorie),
	Id_Lot      TypePieceLot	 REFERENCES LOT(Id_Lot),
	Commentaire varchar(100)  
);



/*------------------------------------------------------------
-- Table: CUMUL
------------------------------------------------------------*/
CREATE TABLE CUMUL(
	Id_Lot    TypePieceLot  REFERENCES LOT(Id_Lot),
	Categorie TypeCategorie	 REFERENCES CATEGORIE(Categorie),
	Nb_Pieces INT   ,
	PRIMARY KEY (Id_Lot, Categorie)
);
go



/*SELECT role.name AS RoleName
FROM sys.server_role_members  
JOIN sys.server_principals AS role  
    ON sys.server_role_members.role_principal_id = role.principal_id  
JOIN sys.server_principals AS member  
    ON sys.server_role_members.member_principal_id = member.principal_id; */

/*------------------------------------------------------------
-- Creation des PROCEDURES
------------------------------------------------------------*/
--Procedure de creation du lot à l'état lancé
CREATE PROCEDURE LancerLot		@nbPièces	Int,
								@modele		TypeModele,
								@message	varchar(100) OUTPUT

AS
DECLARE @codeRetour int;


begin try
	if @nbPièces is null or @nbPièces <= 0
	begin
		set @codeRetour = 1;
		set @message = 'Nb de pièces incohérent';
	end
	else if @modele is Null
	begin
		set @codeRetour = 1;
		set @message = 'Modèle non défini';
	end
	else
	begin
	--vérifier l'existence du modele
		if not EXISTS (select * from MODELE
		where Modele = @modele)
			begin
				-- modele inexistant
				Set @message='Modele '+ CONVERT (varchar (10), @modele) + ' est inexistant';
				set @codeRetour=2;
			end
		else
			begin
			begin transaction
				INSERT INTO LOT (Nb_Pieces_demandees,Modele,Code_Etat)
				VALUES (@nbPièces,@modele,'1')

				--Maj du commentaire Stock
				UPDATE dbo.STOCK
				set DateDerniereCommande = CONVERT(varchar(2), DAY(GETDATE()))+'/'+CONVERT(varchar(2), MONTH(GETDATE()))+'/'+CONVERT(varchar(4),YEAR(GETDATE()))
				where STOCK.Modele = @modele;

			set @codeRetour=0; --OK
			Set @message='Demande de lancement de production pour ' + CONVERT (varchar (10), @nbPièces) + ' pièces ' + CONVERT (varchar (10), @modele);
			commit transaction;
			end
	end
	end try
	begin catch
		--KO erreur base de données
		Set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @codeRetour=3;
		rollback transaction;
	end catch
RETURN (@codeRetour);
go

--Procedure d'annulation du lot lancé
CREATE PROCEDURE AnnulerLot		@idlot		TypePieceLot,
								@message	varchar(100) OUTPUT

AS
DECLARE @codeRetour int;


begin try
	if @idlot is null 
	begin
		set @codeRetour = 1;
		set @message = 'Le paramètre "idlot" ne doit pas être nul';
	end 
	else
	begin
	--vérifier l'existence du lot
		if not EXISTS (select* from LOT where Id_lot = @idlot and Code_Etat = 1)
			begin
				--lot inexistant ou non lancé
				Set @codeRetour = 2;
				Set @message ='Le lot '+ CONVERT (varchar (10), @idlot) + ' est inexistant ou son état n''est pas à lancé';
			end
		else
			begin
			begin transaction
			--On efface le contenu de cumul relatif au lot
				DELETE FROM CUMUL
				where CUMUL.Id_lot = @idlot

			--On efface le lot
				DELETE FROM LOT
				where Id_lot = @idlot


			set @codeRetour=0; --OK
			Set @message='Annulation du lot ' + CONVERT (varchar (10), @idlot);
			commit transaction;
			end
	end
	end try
	begin catch
		--KO erreur base de données
		Set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @codeRetour=3;
		rollback transaction;
	end catch
RETURN (@codeRetour);
go



--Procedure Demarrer Production
CREATE PROCEDURE DemarrerLot		@idlot		TypePieceLot,
									@numpresse  smallint,
									@message	varchar(100) OUTPUT
									
AS
DECLARE @codeRetour int;

begin try
	if @idlot is null 
	begin
		set @codeRetour = 1;
		set @message = 'Le paramètre "idlot" ne doit pas être nul';
	end 
	else if @numpresse is null
	begin
		set @codeRetour = 1;
		set @message = 'Le paramètre "numpresse" ne doit pas être nul';
	end
	else if (SELECT LOT.Code_Etat from LOT where Id_lot = @idlot) <> 1
	begin
		set @codeRetour = 1;
		set @message = 'Le lot ' + CONVERT (varchar (10), @idlot) + ' n''est pas à l''état lancé';
	end
	else if (SELECT MACHINE.Etat_Presse from MACHINE where Num_Presse = @numpresse) <>0
	begin
		set @codeRetour = 1;
		set @message = 'La presse '+ CONVERT (varchar (10), @numpresse) + ' n''est pas libre';
	end
	else 
	begin
	--vérifier l'existence du lot
		if not EXISTS (select* from LOT where Id_lot = @idlot)
			begin
				--lot inexistant
				Set @codeRetour = 2;
				Set @message ='Le lot '+ CONVERT (varchar (10), @idlot) + ' est inexistant';
			end
	--vérifier l'existence de la presse
		else if not exists (select * from MACHINE where Num_Presse = @numpresse)
			begin
				--Presse inexistante
				Set @codeRetour = 3;
				Set @message = 'La presse '+ CONVERT (varchar (10), @numpresse) + ' n''existe pas';
		end
		else
		begin
		begin transaction
		--Affectation presse et changement état_lot
			UPDATE dbo.LOT			
			Set Code_Etat = 2, LOT.Num_Presse = @numpresse
			Where Id_lot = @idlot
			--Affectation presse et changement état_lot
			UPDATE dbo.LOT			
			Set Date_Fabrication = GETDATE ( )
			Where Id_lot = @idlot
		--Changement état_presse--
			UPDATE dbo.MACHINE
			Set Etat_Presse = 1
			Where Num_Presse = @numpresse;
			Set @codeRetour = 0
			Set @message = 'La production pour le lot ' + CONVERT (varchar (10), @idlot) + ' est demarrée sur la presse ' + CONVERT (varchar (10), @numpresse);
			commit transaction;
		end
	end
end try
begin catch
	--KO erreur base de données--
	Set @message='erreur base de données' + ERROR_MESSAGE() ;
	set @codeRetour=4;
	rollback transaction;
end catch
RETURN (@codeRetour);
go


--Procedure Categoriser
CREATE PROCEDURE Categorisation		@idlot		TypePieceLot,
									@diamHL			TypeDiametre,
									@diamHT			TypeDiametre,
									@diamBL			TypeDiametre,
									@diamBT			TypeDiametre,
									@commentaire	varchar(100),
									@message	varchar(100) OUTPUT
--categ existe - lot existe - diam non null - categ non null non rebut		
AS
DECLARE @codePlanning int;
DECLARE @diamModele TypeDiametre;
DECLARE @categPiece TypeCategorie;
begin try
	if @idlot is null
	begin
		set @codePlanning = 1;
		set @message = 'Le paramètre "idlot" ne doit  pas être nul';
	end
	else if (SELECT LOT.Code_Etat from LOT where Id_Lot = @idlot) <> 2 and (SELECT LOT.Code_Etat from LOT where Id_Lot = @idlot) <> 3
	begin
		set @codePlanning = 1;
		set @message = 'Le lot doit être à l''état demarré ou libéré';
	end

	else if @diamBL is null or @diamBT is null or @diamHL is null or @diamHT is null
	begin
		set @codePlanning = 1;
		set @message = 'Diametre non renseigné';
	end
		else if @diamBL <-1 or @diamBT <-1 or @diamHL <-1 or @diamHT <-1
	begin
		set @codePlanning = 1;
		set @message = 'Diametre non renseigné';
	end
	else 
	begin
	--vérifier l'existence du lot--
		if not EXISTS (select* from LOT where Id_lot = @idlot)
			begin
				--lot inexistant--
				Set @codePlanning = 2;
				Set @message ='Lot inexistant';
			end
		else if (select COUNT (Id_Piece) from PIECE where PIECE.Id_Lot = @idlot)=(select Nb_Pieces_demandees from LOT where LOT.Id_Lot = @idlot)
			begin
				--lot inexistant--
				Set @codePlanning = 2;
				Set @message ='Nombre de pièces max atteint';
			end
		else
		begin
		begin transaction
		--Recuperation du diametre
		--Lancement de la fonction categorisation
			SELECT @diamModele = Diametre FROM MODELE JOIN LOT ON MODELE.Modele = LOT.Modele WHERE Id_Lot = @idlot; 
			SELECT @categPiece = dbo.fn_CategoriserPiece(@diamModele, @diamHL , @diamHT , @diamBL , @diamBT)--diambase, HL,HT,BL,BT
		--Insertion de la piece dans la table
			INSERT PIECE 
			VALUES (@diamHL , @diamHT , @diamBL , @diamBT, @categPiece, @idlot, @commentaire)
			Set @codePlanning = 0
			Set @message = 'Pièce enregistrée dans le lot ' + CONVERT (varchar (10), @idlot) + ' : ' + CONVERT (varchar (10), @categPiece);
			commit transaction;
		end
	end
end try
begin catch
	--KO erreur base de données--
	Set @message='erreur base de données' + ERROR_MESSAGE() ;
	set @codePlanning=4;
	rollback transaction;
end catch
RETURN (@codePlanning);
go



--Procedure pour passer la presse en statut "Libérée"
CREATE procedure Liberer_presse		@idlot TypePieceLot,
									@message varchar(100) output

as
declare @code_retour int;
	begin try
		
		--Verification si le numéro de presse n'est pas null
		if @idlot is null
			begin
				set @message = 'Numéro de lot invalide';
				set @code_retour = 1;
			end
		--Verification si le numéro de lot existe
		else if not exists (select Id_Lot from LOT where Id_Lot = @idlot)
			begin
				set @message = 'Le lot ' + CONVERT (varchar(10),@idlot) + ' n''existe pas';
				set @code_retour = 2;
			end

		--Verification si la presse n'est pas déjà en état "Libérée"
		else if  (select Etat_Presse from MACHINE 
					JOIN LOT on MACHINE.Num_Presse = LOT.Num_Presse 
					where Id_Lot = @idlot) = 0   
			begin
				set  @message = 'La presse est déjà en état "Libérée"';
				set @code_retour = 2;		
			end
		else
		begin
		begin transaction	
				--Passage de la presse en état "Libérée"
				UPDATE MACHINE
				set Etat_Presse = 0
				from MACHINE
				JOIN LOT ON MACHINE.Num_Presse = LOT.Num_Presse
				where Id_Lot = @idlot;

				UPDATE LOT
				set Code_Etat = 3
				where Id_Lot = @idlot;

				set @message = 'La presse a été basculé en état "Libérée"' ;
				set @code_retour = 0;
		commit transaction;	
		end
	end try	
	begin catch
		Set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @code_retour=3;
		rollback transaction;
	end catch
return (@code_retour);
go


--Procedure Arreter Production
CREATE PROCEDURE ArretLot			@idlot		TypePieceLot,
									@message	varchar(100) OUTPUT
									
AS
DECLARE @codeRetour int;

begin try
	if @idlot is null
	begin
		set @codeRetour = 1;
		set @message = 'Le paramètre "idlot" ne doit pas être nul';
	end
	else if (SELECT LOT.Code_Etat from LOT where Id_lot = @idlot) <> 3
	begin
		set @codeRetour = 1;
		set @message = 'Le lot ' + CONVERT (varchar (10), @idlot) + ' n''est pas à l''état libéré';
	end
	else 
	begin
	--vérifier l'existence du lot
		if not EXISTS (select* from LOT where Id_lot = @idlot)
			begin
				--lot inexistant
				Set @codeRetour = 2;
				Set @message ='Le lot '+ CONVERT (varchar (10), @idlot) + ' est inexistant';
			end
		else
		begin
		begin transaction
		--Mise à jour des moyennes, max, min et écart types
			UPDATE dbo.LOT			
			Set Moyenne_HL = convert(decimal(10, 5),(SELECT AVG (Diametre_HL)from PIECE where PIECE.Id_Lot=@idlot)), 
			Moyenne_HT = convert(decimal(10, 5),(SELECT AVG (Diametre_HT)from PIECE where PIECE.Id_Lot=@idlot)),
			Moyenne_BL = convert(decimal(10, 5),(SELECT AVG (Diametre_BL)from PIECE where PIECE.Id_Lot=@idlot)),
			Moyenne_BT = convert(decimal(10, 5),(SELECT AVG (Diametre_BT)from PIECE where PIECE.Id_Lot=@idlot)),
			Minimum_HL = (SELECT MIN (Diametre_HL)from PIECE where PIECE.Id_Lot=@idlot),
			Minimum_HT = (SELECT MIN (Diametre_HT)from PIECE where PIECE.Id_Lot=@idlot),
			Minimum_BL = (SELECT MIN (Diametre_BL)from PIECE where PIECE.Id_Lot=@idlot),
			Minimum_BT = (SELECT MIN (Diametre_BT)from PIECE where PIECE.Id_Lot=@idlot),
			Maximum_HL = (SELECT MAX (Diametre_HL)from PIECE where PIECE.Id_Lot=@idlot),
			Maximum_HT = (SELECT MAX (Diametre_HT)from PIECE where PIECE.Id_Lot=@idlot),
			Maximum_BL = (SELECT MAX (Diametre_BL)from PIECE where PIECE.Id_Lot=@idlot),
			Maximum_BT = (SELECT MAX (Diametre_BT)from PIECE where PIECE.Id_Lot=@idlot),
			Ecart_Type_HL = convert(decimal(10, 5),(SELECT STDEV (Diametre_HL)from PIECE where PIECE.Id_Lot=@idlot)),
			Ecart_Type_HT = convert(decimal(10, 5),(SELECT STDEV (Diametre_HT)from PIECE where PIECE.Id_Lot=@idlot)),
			Ecart_Type_BL = convert(decimal(10, 5),(SELECT STDEV (Diametre_BL)from PIECE where PIECE.Id_Lot=@idlot)),
			Ecart_Type_BT = convert(decimal(10, 5),(SELECT STDEV (Diametre_BT)from PIECE where PIECE.Id_Lot=@idlot))

			Where Id_lot = @idlot
			--Mise à jour de l'état lot
			UPDATE LOT
			set Code_Etat = 4
			where Id_Lot = @idlot;
			--renvoi code retour
			Set @codeRetour = 0;
			Set @message ='Le lot ' + CONVERT (varchar (10), @idlot) + 'est passé en état "Arrêté". Statistiques mises à jour';

			commit transaction;
		end
	end
end try
begin catch
	--KO erreur base de données--
	Set @message='erreur base de données' + ERROR_MESSAGE() ;
	set @codeRetour=4;
	rollback transaction;
end catch
RETURN (@codeRetour);
go


--Procedure de sortie de pièces
CREATE PROCEDURE SortieStock	@nbPiècesSorties	Int,
								@categorie			TypeCategorie,
								@modele				TypeModele,
								@message			varchar(100) OUTPUT

AS
DECLARE @codeRetour int;


begin try
	if @nbPiècesSorties is null or @nbPiècesSorties <= 0
	begin
		set @codeRetour = 1;
		set @message = 'Nb de pièces incohérent';
	end
	else if @categorie is Null
	begin
		set @codeRetour = 1;
		set @message = 'Categorie inconnue';
	end
	else if @modele is Null
	begin
		set @codeRetour = 1;
		set @message = 'Modèle non défini';
	end
	else
	begin
	--vérifier l'existence du modele
		if not EXISTS (select * from MODELE
		where Modele = @modele)
			begin
				-- modele inexistant
				Set @message='Modele "'+ CONVERT (varchar (10), @modele) + '" inexistant';
				set @codeRetour=2;
			end
		else if not EXISTS (select * from CATEGORIE
		where Categorie = @categorie)
			begin
				-- modele inexistant
				Set @message='Categorie "'+ CONVERT (varchar (10), @categorie) + '" inexistante';
				set @codeRetour=2;
			end
			--Verification si le retrait est possible
		else if (SELECT Quantite_Stock FROM STOCK WHERE Modele = @modele AND Categorie = @categorie) - @nbPiècesSorties < 0
			begin
				set @codeRetour = 2;
				set @message = 'Opération impossible - Le stock est insuffisant';
			end
		else
			begin
			begin transaction
				UPDATE STOCK
				SET Quantite_Stock = Quantite_Stock-@nbPiècesSorties
				WHERE Modele = @modele
				AND Categorie = @categorie

			set @codeRetour=0; --OK
			set @message = 'Sortie de '+ CONVERT (varchar (10), @nbPiècesSorties) + ' pièces effectuée pour le modele ' + CONVERT (varchar (10), @modele) + ' catégorie ' + CONVERT (varchar (10), @categorie);
			commit transaction;
			end
	end
	end try
	begin catch
		--KO erreur base de données
		Set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @codeRetour=3;
		rollback transaction;
	end catch
RETURN (@codeRetour);
go


--Procedure d'entrée pièces en stock
CREATE PROCEDURE EntreeStock	@nbPiècesEntrées	Int,
								@categorie			TypeCategorie,
								@modele				TypeModele,
								@message			varchar(100) OUTPUT

AS
DECLARE @codeRetour int;


begin try
	if @nbPiècesEntrées is null or @nbPiècesEntrées <= 0
	begin
		set @codeRetour = 1;
		set @message = 'Nb de pièces incohérent';
	end
	else if @categorie is Null
	begin
		set @codeRetour = 1;
		set @message = 'Categorie inconnue';
	end
	else if @modele is Null
	begin
		set @codeRetour = 1;
		set @message = 'Modèle non défini';
	end
	else
	begin
	--vérifier l'existence du modele
		if not EXISTS (select * from MODELE
		where Modele = @modele)
			begin
				-- modele inexistant
				Set @message='Modele "'+ CONVERT (varchar (10), @modele) + '" inexistant';
				set @codeRetour=2;
			end
		else if not EXISTS (select * from CATEGORIE
		where Categorie = @categorie)
			begin
				-- modele inexistant
				Set @message='Categorie "'+ CONVERT (varchar (10), @categorie) + '" inexistante';
				set @codeRetour=2;
			end
		else
			begin
			begin transaction
				UPDATE STOCK
				SET Quantite_Stock = Quantite_Stock+@nbPiècesEntrées
				WHERE Modele = @modele
				AND Categorie = @categorie

			set @codeRetour=0; --OK
			set @message = 'Entrée de '+ CONVERT (varchar (10), @nbPiècesEntrées) + ' pièces effectuée pour le modele ' + CONVERT (varchar (10), @modele) + ' catégorie ' + CONVERT (varchar (10), @categorie);
			commit transaction;
			end
	end
	end try
	begin catch
		--KO erreur base de données
		Set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @codeRetour=3;
		rollback transaction;
	end catch
RETURN (@codeRetour);
go

-----Procédure de création de catégories dans cumul
CREATE PROCEDURE CreerCumul			@idlot	TypePieceLot,
									@message	varchar(50) OUTPUT
									
AS
DECLARE @codePlanning int;

begin try
	if @idlot is null
	begin
		set @codePlanning = 1;
		set @message = 'Le paramètre "idlot" ne doit pas être nul';
	end
	else
	begin
	--vérifier l'existence du lot--
		if not EXISTS (select* from LOT where Id_lot = @idlot)
			begin
				--lot inexistant--
				Set @codePlanning = 2;
				Set @message ='Lot inexistant';
			end
	else
	begin
	begin transaction
	--Insertion du lot dans table cumul
		INSERT CUMUL
		SELECT Id_Lot, Categorie, 0
		from LOT, CATEGORIE
		WHERE Id_Lot = @idlot;
		Set @codePlanning = 0
		Set @message = 'Insertion effectuée'
		commit transaction;
	end
end
end try
begin catch
	--KO erreur base de données--
	Set @message='erreur base de données' + ERROR_MESSAGE() ;
	set @codePlanning=4;
	rollback transaction;
end catch
RETURN (@codePlanning);
go

--Procedure Ajout Machine
CREATE PROCEDURE Ajouter_machine @Num_Presse smallint,
								 @message varchar(200) output	
as
declare @code_retour int;
	begin try
		--Verification si le numéro de presse n'est pas null
		if @Num_Presse is null
			begin
				set @message = 'Numéro de presse invalide';
				set @code_retour = 1;
			end
		--Verification si la presse existe déjà
		else if exists (select Num_Presse from MACHINE where Num_Presse = @Num_Presse )
			begin
				set @message = 'La presse ' + CONVERT (varchar(10),@Num_Presse) + ' existe déjà';
				set @code_retour = 2;
			end
		--Ajout de la presse avec un état à 0
		else
			begin
				begin transaction
				insert MACHINE values (@Num_Presse , '0','0');
				set @message = 'La presse ' + CONVERT (varchar(10),@Num_Presse) + ' a été ajoutée';
				set @code_retour = 0;
				commit transaction;
			end
	end try
	begin catch
		set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @code_retour=3;
		rollback transaction;
	end catch
return @code_retour
go

--Procedure Supprimer_Machine
CREATE PROCEDURE Supprimer_machine		@Num_Presse smallint,
										@message varchar(200) output	
as
declare @code_retour int;
	begin try
		--Verification si le numéro de presse n'est pas null
		if @Num_Presse is null
			begin
				set @message = 'Numéro de presse invalide';
				set @code_retour = 1;
			end
		--Verification si la presse existe
		else if not exists (select Num_Presse from MACHINE where Num_Presse = @Num_Presse )
			begin
				set @message = 'La presse ' + CONVERT (varchar(10),@Num_Presse) + ' n'' existe pas';
				set @code_retour = 2;
			end
		--Suppression de la presse avec valeur à 1 pour "Supprimer"
		else
			begin
				begin transaction
				update MACHINE
				set Supprimée = 1
				where Num_Presse = @Num_Presse;
				set @message = 'La presse ' + CONVERT (varchar(10),@Num_Presse) + ' a été supprimée'
				set @code_retour = 0
				commit transaction;
				
			end
	end try
	begin catch
		set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @code_retour=3;
		rollback transaction;
	end catch
return @code_retour
go


--Procédure Réhabiliter_Machine
CREATE PROCEDURE Rehabiliter_machine	@Num_Presse smallint,
										@message varchar(200) output	
as
declare @code_retour int;
	begin try
		--Verification si le numéro de presse n'est pas null
		if @Num_Presse is null
			begin
				set @message = 'Numéro de presse invalide';
				set @code_retour = 1;
			end
		--Verification si la presse existe
		else if not exists (select Num_Presse from MACHINE where Num_Presse = @Num_Presse )
			begin
				set @message = 'La presse ' + CONVERT (varchar(10),@Num_Presse) + ' n'' existe pas';
				set @code_retour = 2;
			end
		--Suppression de la presse avec valeur à 1 pour "Supprimer"
		else
			begin
				begin transaction
				update MACHINE
				set Supprimée = 0
				where Num_Presse = @Num_Presse;
				set @message = 'La presse ' + CONVERT (varchar(10),@Num_Presse) + ' a été réhabilitée'
				set @code_retour = 0
				commit transaction;
				
			end
	end try
	begin catch
		set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @code_retour=3;
		rollback transaction;
	end catch
return @code_retour
go


--Procédure Supprimer_Modele
CREATE PROCEDURE Supprimer_modele	@m_Modele TypeModele,
									@message varchar(200) output	
as
declare @code_retour int;
	begin try
		--Verification si le modèle n'est pas null
		if @m_Modele is null
			begin
				set @message = 'Modèle invalide';
				set @code_retour = 1;
			end
		--Verification si le modèle existe
		else if not exists (select Modele from MODELE where Modele = @m_Modele )
			begin
				set @message = 'Le modèle ' + CONVERT (varchar(10),@m_Modele) + ' n'' existe pas';
				set @code_retour = 2;
			end
		--Suppression du modèle avec valeur à 1 pour "Supprimer"
		else
			begin
			begin transaction
				update MODELE
				set Supprimée = 1
				where Modele = @m_Modele;
				set @message = 'Le Modèle ' + CONVERT (varchar(10),@m_Modele) + ' a été supprimée'
				set @code_retour = 0
			commit transaction;
			end
	end try
	begin catch
		set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @code_retour=3;
		rollback transaction;
	end catch
return @code_retour
go


--Procédure Réhabiliter_Modele
CREATE PROCEDURE Rehabiliter_Modele	 @m_Modele TypeModele,
									 @message varchar(200) output	
as
declare @code_retour int;
	begin try
		--Verification si le modèle n'est pas null
		if @m_Modele is null
			begin
				set @message = 'Modèle invalide';
				set @code_retour = 1;
			end
		--Verification si le modèle existe
		else if not exists (select Modele from MODELE where Modele = @m_Modele )
			begin
				set @message = 'Le modèle ' + CONVERT (varchar(10),@m_Modele) + ' n'' existe pas';
				set @code_retour = 2;
			end
		--Suppression du modèle avec valeur à 1 pour "Supprimer"
		else
			begin
			begin transaction
				update MODELE
				set Supprimée = 0
				where Modele = @m_Modele;
				set @message = 'Le Modèle ' + CONVERT (varchar(10),@m_Modele) + ' a été réhabilité'
				set @code_retour = 0
			commit transaction;	
			end
	end try
	begin catch
		set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @code_retour=3;
		rollback transaction;
	end catch
return @code_retour
go

--ajouter un modele avec son diametre
CREATE PROCEDURE Ajouter_modele @Modele TypeModele,
								@Diametre TypeDiametre,
								@message varchar(200) output	
as
declare @code_retour int;
	begin try
		--Verification si le modèle ou le diamètre n'est pas null
		if @Modele is null or @Diametre is null
			begin
				set @message = 'Modèle et/ou diamètre incorrect';
				set @code_retour = 1;
			end
		--Verification si le modéle existe déjà
		else if exists (select Modele from MODELE where Modele = @Modele )
			begin
				set @message = 'Le modèle ' + CONVERT (varchar(10),@Modele) + ' existe déjà';
				set @code_retour = 2;
			end
		--Ajout du modèle avec son diamètre
		else
			begin
			begin transaction
				insert MODELE values (@Modele , @Diametre, 0);
				set @message = 'Le modèle ' + CONVERT (varchar(10),@Modele) + ' avec un diamètre de ' + CONVERT (varchar(10),@Diametre) + ' a été ajouté';
				set @code_retour = 0;
			commit transaction;
			end
	end try
	begin catch
		set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @code_retour=3;
		rollback transaction;
	end catch
return @code_retour
go

--Procedure qui appelle la fonction GetRole
CREATE PROCEDURE ps_GetRole		@role varchar(30) output
as
	SELECT @role = dbo.fn_GetRole();
go

CREATE PROCEDURE ps_LotsSelect		@modele TypeModele,
									@message varchar(100) output
as
DECLARE @coderetour int;
begin try
	if @modele is null
	begin
		set @coderetour = 1;
		set @message = 'Le paramètre "modele" ne doit  pas être nul';
	end
	else 
	begin
	--vérifier l'existence du modele--
		if not EXISTS (select* from LOT where Modele = @modele)
			begin
				--lot inexistant--
				Set @coderetour = 2;
				Set @message ='Modele inexistant';
			end
		else
		begin
			SELECT * from fn_LotsSelect(@modele)
		end
	end
end try
begin catch
		set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @coderetour=3;
end catch
return @coderetour


go


--Procédure modifier les seuils
CREATE PROCEDURE modifierSeuils		@modele TypeModele,
									@categorie TypeCategorie,
									@seuil	int,	
									@message varchar(200) output	
as
declare @code_retour int;
	begin try
			--Verification si le seuil n'est pas négatif
		if @seuil is null or @seuil <=0
			begin
				set @message = 'Seuil invalide';
				set @code_retour = 1;
			end
		--Verification si le modèle n'est pas null
		else if @modele is null
			begin
				set @message = 'Modèle invalide';
				set @code_retour = 1;
			end
		--Verification si la categorie n'est pas null
		else if @categorie is null
			begin
				set @message = 'Catégorie invalide';
				set @code_retour = 1;
			end
		--Verification si le modèle existe
		else if not exists (select Modele from MODELE where Modele = @modele )
			begin
				set @message = 'Le modèle ' + CONVERT (varchar(10),@modele) + ' n'' existe pas';
				set @code_retour = 2;
			end
		--Verification si la catégorie existe
		else if not exists (select Categorie from CATEGORIE where Categorie = @categorie )
			begin
				set @message = 'La categorie ' + CONVERT (varchar(10),@categorie) + ' n'' existe pas';
				set @code_retour = 2;
			end
		--Mise à jour du seuil mini
		else
			begin
			begin transaction
				update STOCK
				set Seuil_Mini = @seuil
				where Modele = @modele
				and Categorie = @categorie;

				set @message = 'Le seuil à été modifié pour le modèle '+ CONVERT (varchar(10),@modele) +' - ' +CONVERT (varchar(10),@categorie) + '. Nouveau seuil : ' + CONVERT (varchar(10),@seuil);
				set @code_retour = 0
			commit transaction;	
			end
	end try
	begin catch
		set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @code_retour=3;
		rollback transaction;
	end catch
return @code_retour
go


/*------------------------------------------------------------
-- Creation des Vues
------------------------------------------------------------*/
--Vue concernant les stocks
CREATE VIEW VueStocksCategorie (Modele,Categorie,QuantitéStock,SeuilMini,DerniereCommande)
AS SELECT *
from STOCK
GO

CREATE VIEW VueTousLots AS SELECT *
from LOT
GO

--Vue concernant les ruptures de stock
CREATE VIEW VueRuptureStock AS SELECT *
from STOCK
where Seuil_Mini>=Quantite_Stock
GO

--Vue des états presse
CREATE VIEW VueEtatPresse (NumPresse, EtatPresse)
AS SELECT Num_Presse, Etat_Presse
from MACHINE
where Supprimée = 0
GO

--Vue des lots avec leurs états
CREATE VIEW VueLotPresse (Lot,EtatLot,NumPresse,CodeEtat)
AS SELECT LOT.Id_Lot, ETAT_LOT.Nom_Etat, MACHINE.Num_Presse, LOT.Code_Etat
from LOT 
join ETAT_LOT on LOT.Code_Etat = ETAT_LOT.Code_Etat
LEFT JOIN MACHINE on LOT.Num_Presse = MACHINE.Num_Presse
GO

--Vue des lots lancés
CREATE view VueLotsLances (LotsLancés, Modele, QuantitéDemandée)
as
select Id_Lot, Modele, Nb_Pieces_Demandees
from LOT
where Code_Etat = 1
GO

--Vue des lots demarrer
CREATE View VueLotsDemarres (LotsDémarrés, Modèle, QuantitéDemandée, Presse)
as
select Id_Lot, Modele, Nb_Pieces_demandees, LOT.Num_Presse
from LOT
where LOT.Code_Etat = 2
GO

--Vue des des presses dispos
CREATE VIEW VueEtatPresseDispo (NumPresse, EtatPresse)
AS SELECT Num_Presse, Etat_Presse
from MACHINE
where Etat_Presse = 0
GO

--Vue des lots
CREATE view VueLots
as
select Id_Lot, Modele, Nom_Etat
from LOT
join ETAT_LOT on LOT.Code_Etat = ETAT_LOT.Code_Etat
GO

--Vue pour le resp production
CREATE view VueRespProd (Lot, EtatLot, NumPresse)
as
select Id_Lot, Nom_Etat, MACHINE.Num_Presse
from LOT, ETAT_LOT, MACHINE
where LOT.Code_Etat = ETAT_LOT.Code_Etat
and LOT.Num_Presse = MACHINE.Num_Presse
GO

/*------------------------------------------------------------
-- Creation de Fontion
------------------------------------------------------------*/
--Fonction qui renvoie une categorie en varchar selon 4 mesures
CREATE FUNCTION fn_CategoriserPiece (@diamBase TypeDiametre, @diamHL TypeDiametre, @diamHT TypeDiametre, @diamBL TypeDiametre, @diamBT TypeDiametre)
RETURNS varchar(5)
AS
BEGIN
	DECLARE @categorie TypeCategorie; 
	DECLARE @petitMin TypeDiametre;
	DECLARE @MoyenMin TypeDiametre;
	DECLARE @MoyenMax TypeDiametre;
	DECLARE @GrandMax TypeDiametre;

	--Calcul des intervalles en fonction du diametre de base
	SELECT @petitMin = @diamBase + Tolerance_Mini from CATEGORIE where Categorie = 'PETIT';
	SELECT @MoyenMin = @diamBase + Tolerance_Mini from CATEGORIE where Categorie = 'MOYEN';
	SELECT @MoyenMax = @diamBase + Tolerance_Maxi from CATEGORIE where Categorie = 'MOYEN';
	SELECT @GrandMax = @diamBase + Tolerance_Maxi from CATEGORIE where Categorie = 'GRAND';
	
	-- Conditions d'affectation des categories

	IF @diamHL BETWEEN @petitMin AND @MoyenMin 
	AND @diamHT BETWEEN @petitMin AND @MoyenMin 
	AND @diamBL BETWEEN @petitMin AND @MoyenMin 
	AND @diamBT BETWEEN @petitMin AND @MoyenMin
	BEGIN
	SET @categorie = 'PETIT';
	END
	ELSE IF @diamHL BETWEEN @MoyenMax AND @GrandMax 
	AND @diamHT BETWEEN @MoyenMax AND @GrandMax 
	AND @diamBL BETWEEN @MoyenMax AND @GrandMax 
	AND @diamBT BETWEEN @MoyenMax AND @GrandMax
	BEGIN
	SET @categorie = 'GRAND';
	END
	ELSE IF @diamHL BETWEEN @petitMin AND @MoyenMax 
	AND @diamHT BETWEEN @petitMin AND @MoyenMax 
	AND @diamBL BETWEEN @petitMin AND @MoyenMax 
	AND @diamBT BETWEEN @petitMin AND @MoyenMax
	BEGIN
	SET @categorie = 'MOYEN';
	END
	ELSE IF @diamHL BETWEEN @MoyenMin AND @GrandMax 
	AND @diamHT BETWEEN @MoyenMin AND @GrandMax 
	AND @diamBL BETWEEN @MoyenMin AND @GrandMax 
	AND @diamBT BETWEEN @MoyenMin AND @GrandMax
	BEGIN
	SET @categorie = 'MOYEN';
	END
	ELSE
	BEGIN
	SET @categorie = 'REBUT';
	END
	

	RETURN @categorie
END
GO

--fontion qui retourne le role de l'utilisateur courant
CREATE FUNCTION fn_GetRole ()
RETURNS varchar(50)
AS
BEGIN
--Variable login et mdp
DECLARE @login NVARCHAR(256), @user NVARCHAR(256), @role varchar(20);

--recuperation du login courant
SELECT @login = login_name FROM sys.dm_exec_sessions WHERE session_id = @@SPID;

--recuperation de l'user à partir du login
SELECT @user = d.name
  FROM sys.database_principals AS d
  INNER JOIN sys.server_principals AS s
  ON d.sid = s.sid
  WHERE s.name = @login;


SELECT @role = r.name
  FROM sys.database_role_members AS m
  INNER JOIN sys.database_principals AS r
  ON m.role_principal_id = r.principal_id
  INNER JOIN sys.database_principals AS u
  ON u.principal_id = m.member_principal_id
  WHERE u.name = @user;
	

	RETURN @role
END
GO

--Fonction qui retourne une table de lots en fonction du modele selectionné
CREATE FUNCTION fn_LotsSelect (@modele TypeModele) RETURNS table
AS
RETURN (SELECT * FROM LOT WHERE Modele = @modele)
go



/*------------------------------------------------------------
-- Creation des Triggers
------------------------------------------------------------*/
--Trigger Ajout Piece
CREATE Trigger AjoutPiece
on PIECE
AFTER INSERT
as UPDATE CUMUL
set Nb_Pieces = Nb_Pieces + 1
from inserted
where CUMUL.Id_Lot = inserted.Id_Lot and CUMUL.Categorie = inserted.Categorie
go


--Trigger Cumul
CREATE TRIGGER TriggerCumul

ON LOT
FOR INSERT
AS
declare @idlot TypePieceLot;
declare @message varchar(50);
select @idlot = LOT.Id_Lot from inserted JOIN LOT on inserted.Id_Lot = LOT.Id_Lot
EXEC dbo.CreerCumul @idlot, @message;
go

