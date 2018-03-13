CREATE view [dbo].[VueEtatPresseDispo] (NumPresse, EtatPresse)
 as select Num_Presse, Etat_Presse
 from MACHINE
 where Etat_Presse = 0 and Supprimée = 0
GO