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
	Seuil_Mini     INT   
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
	Id_Lot      TypePieceLot	 REFERENCES LOT(Id_Lot)  
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

/*------------------------------------------------------------
-- Creation des USER et ROLES
------------------------------------------------------------*/
CREATE ROLE CONTROLEUR;
CREATE ROLE RESP_ATELIER;
CREATE ROLE RESP_PRODUCTION;
CREATE ROLE RESP_QUALITE;
CREATE ROLE RESP_APPLI;
CREATE ROLE MAGASINIER
go

CREATE LOGIN resp_appli WITH PASSWORD ='resp_appli';
CREATE LOGIN resp_atelier1 WITH PASSWORD ='resp_atelier1';
CREATE LOGIN resp_atelier2	WITH PASSWORD ='resp_atelier2';
CREATE LOGIN resp_production1 WITH PASSWORD ='resp_production1';
CREATE LOGIN resp_production2 WITH PASSWORD ='resp_production2';
CREATE LOGIN controleur1 WITH PASSWORD ='controleur1';
CREATE LOGIN controleur2 WITH PASSWORD ='controleur2';
CREATE LOGIN controleur3 WITH PASSWORD ='controleur3';
CREATE LOGIN magasinier1 WITH PASSWORD ='magasinier1';
CREATE LOGIN magasinier2 WITH PASSWORD ='magasinier2';
CREATE LOGIN magasinier3 WITH PASSWORD ='magasinier3';
CREATE LOGIN resp_qualité1 WITH PASSWORD ='resp_qualité1';
CREATE LOGIN resp_qualité2 WITH PASSWORD ='resp_qualité2';
go




CREATE USER ederson FROM login resp_appli;
CREATE USER walker FROM login resp_atelier1;
CREATE USER kompany	FROM login resp_atelier2;
CREATE USER otamendi FROM login resp_production1;
CREATE USER danilo FROM login resp_production2;
CREATE USER debruyne FROM login controleur1;
CREATE USER gundogan FROM login controleur2;
CREATE USER dsilva FROM login controleur3;
CREATE USER bsilva FROM login magasinier1;
CREATE USER sane FROM login magasinier2;
CREATE USER sterling FROM login magasinier3;
CREATE USER aguero FROM login resp_qualité1;
CREATE USER guardiola FROM login resp_qualité2;
go

ALTER ROLE RESP_APPLI ADD MEMBER ederson
go

/*------------------------------------------------------------
-- Creation des PROCEDURES
------------------------------------------------------------*/
--Procedure de creation du lot à l'état lancé
CREATE PROCEDURE LancerLot		@etatlot	tinyint,
								@nbPièces	Int,
								@modele		TypeModele,
								@message	varchar(100) OUTPUT

AS
DECLARE @codeRetour int;


begin try
	if @etatlot is null or @etatlot <> 1
	begin
		set @codeRetour = 1;
		set @message = 'Le lot doit être initialisé à l''état lancé';
	end
	else if @nbPièces is null or @nbPièces <= 0
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
				INSERT INTO LOT (Nb_Pieces_demandees,Modele,Code_Etat)
				VALUES (@nbPièces,@modele,@etatlot)
			set @codeRetour=0; --OK
			Set @message='Demande de lancement de production pour ' + CONVERT (varchar (10), @nbPièces) + ' pièces ' + CONVERT (varchar (10), @modele);
			end
	end
	end try
	begin catch
		--KO erreur base de données
		Set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @codeRetour=3;
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
	else if (SELECT LOT.Code_Etat from LOT where Id_Lot = @idlot) <> 2
	begin
		set @codePlanning = 1;
		set @message = 'Le lot n''est pas à l''état demarré';
	end

	else if @diamBL is null or @diamBT is null or @diamHL is null or @diamHT is null
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
			SELECT @categPiece = dbo.fn_CategoriserPiece(@diamModele, @diamHL , @diamHT , @diamBL , @diamBT )--diambase, HL,HT,BL,BT
		--Insertion de la piece dans la table
			INSERT PIECE 
			VALUES (@diamHL , @diamHT , @diamBL , @diamBT, @categPiece, @idlot)
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
			
		end
	end try	
	begin catch
		Set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @code_retour=3;
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
			Set @message ='Les statistiques ont été mises à jour pour le lot ' + CONVERT (varchar (10), @idlot);

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
				UPDATE STOCK
				SET Quantite_Stock = Quantite_Stock-@nbPiècesSorties
				WHERE Modele = @modele
				AND Categorie = @categorie

			set @codeRetour=0; --OK
			set @message = 'Sortie de '+ CONVERT (varchar (10), @nbPiècesSorties) + ' pièces effectuée pour le modele ' + CONVERT (varchar (10), @modele) + ' catégorie ' + CONVERT (varchar (10), @categorie);
			end
	end
	end try
	begin catch
		--KO erreur base de données
		Set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @codeRetour=3;
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
				UPDATE STOCK
				SET Quantite_Stock = Quantite_Stock+@nbPiècesEntrées
				WHERE Modele = @modele
				AND Categorie = @categorie

			set @codeRetour=0; --OK
			set @message = 'Entrée de '+ CONVERT (varchar (10), @nbPiècesEntrées) + ' pièces effectuée pour le modele ' + CONVERT (varchar (10), @modele) + ' catégorie ' + CONVERT (varchar (10), @categorie);
			end
	end
	end try
	begin catch
		--KO erreur base de données
		Set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @codeRetour=3;
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
				insert MACHINE values (@Num_Presse , '0','0');
				set @message = 'La presse ' + CONVERT (varchar(10),@Num_Presse) + ' a été ajouté';
				set @code_retour = 0;
			end
	end try
	begin catch
		set @message='erreur base de données' + ERROR_MESSAGE() ;
		set @code_retour=3;
	end catch
return @code_retour
go
/*------------------------------------------------------------
-- Creation des Vues
------------------------------------------------------------*/
--Vue concernant les stocks
CREATE VIEW VueStocksCategorie AS SELECT *
from STOCK
GO

--Vue concernant les ruptures de stock
CREATE VIEW VueRuptureStock AS SELECT *
from STOCK
where Seuil_Mini>=Quantite_Stock
GO

CREATE VIEW VueEtatPresse AS SELECT *
from MACHINE
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


