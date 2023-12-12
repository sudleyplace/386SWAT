extern	long segoff2dd(char *tok);
extern	unsigned int segoff2seg(char *tok);
extern	unsigned long segoff2off(char *tok);
extern	void splitsegoff(char *tok,struct SSF_struct *symdata);
extern	void CheckSel(struct SSF_struct *pData);
extern	void UpdateSelBase(char *pszSegSel,unsigned long dwLinAddr);
extern	void load_map(char *path);
